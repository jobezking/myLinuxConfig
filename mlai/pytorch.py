# pytorch_paddle.py

print("\n====================")
print(" PyTorch Test")
print("====================")
try:
    import torch
    print("Torch Version:", torch.__version__)
    print("CUDA Available:", torch.cuda.is_available())
    if torch.cuda.is_available():
        print("GPU Name:", torch.cuda.get_device_name(0))
except Exception as e:
    print("PyTorch Error:", e)


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
