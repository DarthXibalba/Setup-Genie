#!$HOME/miniconda3/envs/h2ogpt bash -l
# TODO: Get this script to work by fixing the above line ^
# For more info:
# [Rob Mulla Youtube](https://www.youtube.com/watch?v=Coj72EzmX20&ab_channel=RobMulla)
# https://github.com/h2oai/h2ogpt
# https://github.com/h2oai/h2ogpt/blob/main/docs/README_GPU.md
# https://github.com/h2oai/h2ogpt/blob/main/docs/FAQ.md#low-memory-mode

# Get the absolute path of the script directory
script_dir="$(dirname "$(realpath "$0")")"
wget_download="$script_dir/helper_scripts/wget-download.sh"

# Install packages
pip install -r requirements.txt
pip install -r reqs_optional/requirements_optional_langchain.txt
pip install -r reqs_optional/requirements_optional_gpt4all.txt

# Download to local machine
h2oURL="https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGML/resolve/main/llama-2-7b-chat.ggmlv3.q8_0.bin"
#h2oPath="$script_dir/../setup-files/llama-2-7b-chat.ggmlv3.q8_0.bin"
h2oPath="$HOME/h2ogpt/"
$wget_download $h2oURL $h2oPath

# Run
cd $h2oPath
python generate.py --base_model='llama' --prompt_type=llama2
#python generate.py --base_model='llama' --prompt_type=llama2 --share=False --gradio_offline_level=1 --score_model=None 
echo "Please open a browser and visit: http://127.0.0.1:7860"
echo "or: http://localhost:7860"
