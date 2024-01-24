# Resnet50 Inference

Resnet50 Inference BKC.

## Model Information

| **Use Case** | **Framework** | **Model Repo** | **Branch/Commit/Tag** | **Optional Patch** |
|:---:| :---: |:--------------:|:---------------------:|:------------------:|
|  Inference   |    Pytorch    |       -        |           -           |         -          |

# Pre-Requisite
* Host has Intel® Data Center GPU MAX or FLEX or ARC
* Host has installed latest Intel® Data Center GPU Max & Flex Series Drivers https://dgpu-docs.intel.com/driver/installation.html
* Host has installed [Intel® Extension for PyTorch](https://intel.github.io/intel-extension-for-pytorch/xpu/latest/)

# Prepare Dataset
## Dataset: imagenet
Default is dummy dataset.
ImageNet is recommended, the download link is https://image-net.org/challenges/LSVRC/2012/2012-downloads.php.


## Inference
1. `git clone https://github.com/IntelAI/models.git`
2. `cd models_v2/pytorch/resnet50v1_5/inference/gpu`
3. Run `setup.sh` this will install all the required dependencies & create virtual environment `venv`.
4. Activate virtual env: `. ./venv/bin/activate`
5. Setup required environment paramaters

| **Parameter**                |                                  **export command**                                  |
|:---------------------------:|:------------------------------------------------------------------------------------:|
| **MULTI_TILE**               | `export MULTI_TILE=True` (True or False)                                             |
| **PLATFORM**                 | `export PLATFORM=PVC` (PVC or ATS-M or ARC)                                                 |
| **BATCH_SIZE** (optional)    |                               `export BATCH_SIZE=1024`                                |
| **PRECISION** (optional)     |`export PRECISION=INT8` (INT8,FP32, Fp16 for all platform, BF16 and TF32 only for PVC  |
| **OUTPUT_DIR** (optional)    |                               `export OUTPUT_DIR=$PWD`                               |
|**NUM_ITERATIONS** (optional) |                               `export NUM_ITERATIONS=500`                             |
| **DATASET_DIR** (optional)   |                               `export DATASET_DIR=--dummy`                           |
6. Run `run_model.sh`

## Output

Single-tile output will typically looks like:

```
Test: [500/500] Time  0.039 ( 0.042)    Loss 8.4575e+00 (8.4625e+00)    Acc@1   0.20 (  0.10)   Acc@5   0.59 (  0.50)
Quantization Evalution performance: batch size:1024, throughput:26373.51 image/sec, Acc@1:0.10, Acc@5:0.50
```

Multi-tile output will typically looks like:
```
Test: [500/500] Time  0.040 ( 0.044)    Loss 8.4575e+00 (8.4625e+00)    Acc@1   0.20 (  0.10)   Acc@5   0.59 (  0.50)
Quantization Evalution performance: batch size:1024, throughput:25780.13 image/sec, Acc@1:0.10, Acc@5:0.50
Test: [500/500] Time  0.039 ( 0.044)    Loss 8.4575e+00 (8.4625e+00)    Acc@1   0.20 (  0.10)   Acc@5   0.59 (  0.50)
Quantization Evalution performance: batch size:1024, throughput:26216.49 image/sec, Acc@1:0.10, Acc@5:0.50
```

Final results of the inference run can be found in `results.yaml` file.
```
results:
 - key: throughput
   value: 26373.51
   unit: fps
 - key: latency
   value: 0.0388268379900893
   unit: s
 - key: accuracy
   value: 0.100
   unit: top1
```
