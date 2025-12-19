import tensorflow as tf
import torch

print("TF GPU:", tf.config.list_physical_devices('GPU'))
print("PyTorch GPU:", torch.cuda.is_available())
print("Device Name:", torch.cuda.get_device_name(0))
