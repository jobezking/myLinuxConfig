rm -rf venv .venv
/usr/bin/python3.13 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
sudo apt update
sudo apt install vulkan-tools libvulkan-dev -y
# vulkaninfo | less
pip3 uninstall av
sudo apt install libavformat-dev libavcodec-dev libavdevice-dev libavutil-dev libswscale-dev libswresample-dev libavfilter-dev -y
pip3 install --no-binary av av
python3 -c "import av; print(av.library_versions)"
