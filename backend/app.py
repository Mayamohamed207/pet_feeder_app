from fastapi import FastAPI, HTTPException, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import base64
import numpy as np
import tensorflow as tf
from PIL import Image
import io
import traceback
from datetime import datetime
import httpx

app = FastAPI(title="Cat Detector API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ESP32_CAPTURE_URL = f"https://unsunny-botchiest-khloe.ngrok-free.dev/capture"

# Load TFLite model
try:
    interpreter = tf.lite.Interpreter(model_path="model.tflite")
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    print(" TFLite model loaded successfully")
except Exception as e:
    raise RuntimeError(f"Failed to load model: {e}")

# Storage for latest image and prediction
latest_data = {
    "image_bytes": None,
    "timestamp": None,
    "prediction": None
}

class ImageData(BaseModel):
    image: str  # base64-encoded image

def preprocess(image_bytes: bytes) -> np.ndarray:
    """Preprocess image for TFLite model"""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img = img.resize((224, 224))
    arr = np.array(img, dtype=np.float32) / 255.0
    return np.expand_dims(arr, axis=0)

def run_prediction(image_bytes: bytes) -> dict:
    """Run TFLite model prediction on image bytes"""
    tensor = preprocess(image_bytes)
    interpreter.set_tensor(input_details[0]['index'], tensor)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])[0]
    
    not_cat = float(output[0])
    cat = float(output[1])
    
    return {
        "isCat": cat < not_cat,  # Fixed: cat should be GREATER than not_cat
        "confidence": float(max(cat, not_cat)),
        "catProbability": cat,
        "notCatProbability": not_cat,
        "timestamp": datetime.now().isoformat()
    }


# ========== ESP32 CAMERA ENDPOINTS ==========

@app.get("/analyze-live")
async def analyze_camera():
    """
    Fetches image directly from ESP32-CAM and runs prediction
    Used when you want real-time analysis without storing
    """
    try:
        # Fetch image from ESP32
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(ESP32_CAPTURE_URL)
            
        if response.status_code != 200:
            raise HTTPException(
                status_code=502, 
                detail=f"Failed to fetch image from ESP32. Status: {response.status_code}"
            )
            
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=502, 
            detail=f"ESP32 connection error: {exc}. Check if ESP32 is online at {ESP32_IP}"
        )
    
    try:
        # Get image bytes and run prediction
        image_bytes = response.content
        print(f"Fetched {len(image_bytes)} bytes from ESP32")
        
        # Step 3: Run prediction
        prediction = run_prediction(image_bytes)
        
        # Also store it as latest data
        latest_data["image_bytes"] = image_bytes
        latest_data["timestamp"] = datetime.now().isoformat()
        latest_data["prediction"] = prediction
        
        print(f"Live prediction: {prediction}")
        
        return {
            "status": "success",
            "source": ESP32_CAPTURE_URL,
            "size_bytes": len(image_bytes),
            "prediction": prediction
        }
        
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"Model processing error: {str(e)}\n{traceback.format_exc()}"
        )


@app.post("/capture-and-store")
async def capture_and_store():
    """
    Fetches image from ESP32-CAM and stores it (without prediction)
    Flutter app can then call /get-prediction separately
    """
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(ESP32_CAPTURE_URL)
            
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="Failed to fetch image from ESP32")
            
    except httpx.RequestError as exc:
        raise HTTPException(
            status_code=502, 
            detail=f"ESP32 connection error: {exc}"
        )
    
    try:
        image_bytes = response.content
        
        # Store image without prediction
        latest_data["image_bytes"] = image_bytes
        latest_data["timestamp"] = datetime.now().isoformat()
        latest_data["prediction"] = None  # Clear old prediction
        
        print(f"Image captured and stored: {len(image_bytes)} bytes")
        
        return {
            "status": "success",
            "message": "Image captured and stored",
            "source": ESP32_CAPTURE_URL,
            "size_bytes": len(image_bytes),
            "timestamp": latest_data["timestamp"]
        }
        
    except Exception as e:
        print(f" Capture error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ========== IMAGE UPLOAD ENDPOINTS ==========

@app.post("/upload-image")
async def upload_image(file: UploadFile = File(...)):
    """
    Endpoint to receive image from ESP32 via multipart/form-data
    ESP32 sends: multipart/form-data with image file
    """
    try:
        # Read image bytes
        image_bytes = await file.read()
        
        # Store image
        latest_data["image_bytes"] = image_bytes
        latest_data["timestamp"] = datetime.now().isoformat()
        latest_data["prediction"] = None  # Clear old prediction
        
        print(f"Image uploaded: {len(image_bytes)} bytes at {latest_data['timestamp']}")
        
        return {
            "status": "success",
            "message": "Image uploaded successfully",
            "size_bytes": len(image_bytes),
            "timestamp": latest_data["timestamp"]
        }
    except Exception as e:
        print(f" Upload error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/upload-image-base64")
def upload_image_base64(data: ImageData):
    """
    Endpoint to receive base64-encoded image from ESP32
    ESP32 sends: {"image": "base64_string"}
    """
    try:
        # Decode base64 image
        image_bytes = base64.b64decode(data.image)
        
        # Store image
        latest_data["image_bytes"] = image_bytes
        latest_data["timestamp"] = datetime.now().isoformat()
        latest_data["prediction"] = None  # Clear old prediction
        
        print(f" Base64 image uploaded: {len(image_bytes)} bytes")
        
        return {
            "status": "success",
            "message": "Image uploaded successfully",
            "size_bytes": len(image_bytes),
            "timestamp": latest_data["timestamp"]
        }
    except Exception as e:
        print(f"❌ Upload error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ========== PREDICTION ENDPOINTS ==========

@app.get("/get-prediction")
def get_prediction():
    """
    Endpoint to get prediction from the last uploaded/captured image
    Flutter app calls this to get the result
    Returns cached prediction if available
    """
    try:
        # Check if image exists
        if latest_data["image_bytes"] is None:
            raise HTTPException(
                status_code=404,
                detail="No image available. Upload an image first using /upload-image or /capture-and-store"
            )
        
        # Check if prediction already exists (cached)
        if latest_data["prediction"] is not None:
            print(" Returning cached prediction")
            return latest_data["prediction"]
        
        # Run new prediction
        print(" Running new prediction...")
        result = run_prediction(latest_data["image_bytes"])
        
        # Cache the prediction
        latest_data["prediction"] = result
        
        print(f" Prediction: {result}")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Prediction failed: {str(e)}\n{traceback.format_exc()}"
        )


@app.post("/predict")
def predict(data: ImageData):
    """
    Original endpoint: receive base64 image and return prediction immediately
    Useful for direct testing without storing
    """
    try:
        image_bytes = base64.b64decode(data.image)
        result = run_prediction(image_bytes)
        print(f"Direct prediction: {result}")
        return result
    except Exception as e:
        print(f"❌ Error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"{str(e)}\n{traceback.format_exc()}"
        )


# ========== STATUS & INFO ENDPOINTS ==========

@app.get("/")
def root():
    return {
        "status": "API is running",
        "esp32_ip": ESP32_IP,
        "endpoints": {
            "live_analysis": "GET /analyze-live (fetch from ESP32 + predict immediately)",
            "capture_store": "POST /capture-and-store (fetch from ESP32 + store only)",
            "upload_multipart": "POST /upload-image (multipart/form-data)",
            "upload_base64": "POST /upload-image-base64 (JSON with base64)",
            "get_prediction": "GET /get-prediction (predict from stored image)",
            "direct_predict": "POST /predict (base64 -> immediate result)",
            "status": "GET /status (check system status)"
        }
    }


@app.get("/status")
def status():
    """Check if image is available and get system info"""
    return {
        "image_uploaded": latest_data["image_bytes"] is not None,
        "image_size_bytes": len(latest_data["image_bytes"]) if latest_data["image_bytes"] else 0,
        "timestamp": latest_data["timestamp"],
        "prediction_cached": latest_data["prediction"] is not None,
        "esp32_configured": ESP32_IP is not None,
        "esp32_url": ESP32_CAPTURE_URL,
        "model_loaded": interpreter is not None
    }


@app.get("/test-esp32")
async def test_esp32():
    """Test if ESP32 is reachable"""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(ESP32_CAPTURE_URL)
        
        return {
            "status": "success",
            "esp32_reachable": True,
            "status_code": response.status_code,
            "image_size": len(response.content),
            "esp32_url": ESP32_CAPTURE_URL
        }
    except Exception as e:
        return {
            "status": "error",
            "esp32_reachable": False,
            "error": str(e),
            "esp32_url": ESP32_CAPTURE_URL
        }


if __name__ == "__main__":
    import uvicorn
    print("=" * 60)
    print("🐱 Starting Cat Detector API")
    print("=" * 60)
    print(f"ESP32 IP: {ESP32_IP}")
    print(f"Capture URL: {ESP32_CAPTURE_URL}")
    print("\n📡 Available Endpoints:")
    print("   GET  /analyze-live         - Fetch from ESP32 + predict")
    print("   POST /capture-and-store    - Fetch from ESP32 + store")
    print("   POST /upload-image         - Upload image (multipart)")
    print("   POST /upload-image-base64  - Upload base64 image")
    print("   GET  /get-prediction       - Get prediction from stored image")
    print("   POST /predict              - Direct predict (base64)")
    print("   GET  /status               - System status")
    print("   GET  /test-esp32           - Test ESP32 connection")
    print("=" * 60)
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)