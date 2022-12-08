<!--- 50. AI Kit -->
## Run the model

Setup your environment using the instructions below, depending on if you are
using [AI Kit](/docs/general/tensorflow/AIKit.md):

<table>
  <tr>
    <th>Setup using AI Kit on Linux</th>
    <th>Setup without AI Kit on Linux</th>
    <th>Setup without AI Kit on Windows</th>
  </tr>
  <tr>
    <td>
      <p>To run using AI Kit on Linux you will need:</p>
      <ul>
        <li>numactl
        <li>wget
        <li>Activate the tensorflow conda environment
        <pre>conda activate tensorflow</pre>
      </ul>
    </td>
    <td>
      <p>To run without AI Kit on Linux you will need:</p>
      <ul>
        <li>Python 3
        <li><a href="https://pypi.org/project/intel-tensorflow/">intel-tensorflow>=2.5.0</a>
        <li>git
        <li>numactl
        <li>wget
        <li>A clone of the Model Zoo repo<br />
        <pre>git clone https://github.com/IntelAI/models.git</pre>
      </ul>
    </td>
    <td>
      <p>To run without AI Kit on Windows you will need:</p>
      <ul>
        <li><a href="/docs/general/Windows.md">Intel Model Zoo on Windows Systems prerequisites</a>
        <li>A clone of the Model Zoo repo<br />
        <pre>git clone https://github.com/IntelAI/models.git</pre>
      </ul>
    </td>
  </tr>
</table>

After finishing the setup above, download the pretrained model based on `PRECISION` and set the
`PRETRAINED_MODEL` environment var to the path to the frozen graph.
If you run on Windows, please use a browser to download the pretrained model using the link below.

For Linux, run:
```
# FP32 Pretrained model
wget https://storage.googleapis.com/intel-optimized-tensorflow/models/v1_8/inceptionv3_fp32_pretrained_model.pb
export PRETRAINED_MODEL=$(pwd)/inceptionv3_fp32_pretrained_model.pb
```
```
# Int8 Pretrained model
wget https://storage.googleapis.com/intel-optimized-tensorflow/models/v1_8/inceptionv3_int8_pretrained_model.pb
export PRETRAINED_MODEL=$(pwd)/inceptionv3_int8_pretrained_model.pb
```
Intel® Neural Compressor int8 quantized Inception V3 pre-trained model is available as another option to download and try.
```
wget https://storage.googleapis.com/intel-optimized-tensorflow/intel-neural-compressor/v1_13/inceptionv3-inc-int8-inference.pb
export PRETRAINED_MODEL=$(pwd)/inceptionv3-inc-int8-inference.pb
```
 Check the [instructions](/quickstart/image_recognition/tensorflow/generate_int8/README.md) for more details on how to quantize FP32 model using Intel® Neural Compressor.

Set the environment variables and run quickstart script on either Linux or Windows systems. See the [list of quickstart scripts](#quick-start-scripts) for details on the different options.

### Run on Linux

```
# cd to your model zoo directory
cd models

export PRETRAINED_MODEL=<path to the frozen graph downloaded above>
export DATASET_DIR=<path to the ImageNet TF records>
export PRECISION=<set the precision to "int8" or "fp32">
export OUTPUT_DIR=<path to the directory where log files will be written>
# For a custom batch size, set env var `BATCH_SIZE` or it will run with a default value.
export BATCH_SIZE=<customized batch size value>

./quickstart/image_recognition/tensorflow/inceptionv3/inference/cpu/<script name>.sh
```

### Run on Windows
Using a `cmd.exe` run:
```
# cd to your model zoo directory
cd models

set PRETRAINED_MODEL=<path to the frozen graph downloaded above>
set DATASET_DIR=<path to the ImageNet TF records>
set PRECISION=<set the precision to "int8" or "fp32">
set OUTPUT_DIR=<directory where log files will be written>
# For a custom batch size, set env var `BATCH_SIZE` or it will run with a default value.
set BATCH_SIZE=<customized batch size value>

bash quickstart\image_recognition\tensorflow\inceptionv3\inference\cpu\<script name>.sh
```
> Note: You may use `cygpath` to convert the Windows paths to Unix paths before setting the environment variables. 
As an example, if the dataset location on Windows is `D:\user\ImageNet`, convert the Windows path to Unix as shown:
> ```
> cygpath D:\user\ImageNet
> /d/user/ImageNet
>```
>Then, set the `DATASET_DIR` environment variable `set DATASET_DIR=/d/user/ImageNet`.