# tensorflow_paddle.py

print("\n====================")
print(" TensorFlow Test")
print("====================")
try:
    import tensorflow as tf
    print("TF Version:", tf.__version__)
    print("GPU Available:", tf.config.list_physical_devices("GPU"))
except Exception as e:
    print("TensorFlow Error:", e)


print("\n====================")
print(" PaddlePaddle Test")
print("====================")
try:
    import paddle
    print("Paddle Version:", paddle.__version__)
    print("CUDA Available:", paddle.device.is_compiled_with_cuda())
    if paddle.device.is_compiled_with_cuda():
        print("GPU Count:", paddle.device.cuda.device_count())
        print("GPU Name:", paddle.device.cuda.get_device_name(0))
except Exception as e:
    print("Paddle Error:", e)

print("\nAll tests complete.\n")
