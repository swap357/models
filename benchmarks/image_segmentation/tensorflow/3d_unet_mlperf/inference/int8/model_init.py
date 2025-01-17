#
# -*- coding: utf-8 -*-
#
# Copyright (c) 2021 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: EPL-2.0
#

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from common.base_model_init import BaseModelInitializer
from common.base_model_init import set_env_var

import os
from argparse import ArgumentParser


class ModelInitializer(BaseModelInitializer):
    """initialize mode and run benchmark"""

    def __init__(self, args, custom_args=[], platform_util=None):
        super(ModelInitializer, self).__init__(args, custom_args, platform_util)

        self.benchmark_command = ""
        if not platform_util:
            raise ValueError("Did not find any platform info.")

        # use default batch size if -1
        if self.args.batch_size == -1:
            self.args.batch_size = 10

        # set num_inter_threads and num_intra_threads
        self.set_num_inter_intra_threads()

        arg_parser = ArgumentParser(description='Parse args')

        arg_parser.add_argument("--warmup-steps", dest='warmup_steps',
                                type=int, default=10,
                                help="number of warmup steps")
        arg_parser.add_argument("--steps", dest='steps',
                                type=int, default=50,
                                help="number of steps")
        arg_parser.add_argument(
            '--kmp-blocktime', dest='kmp_blocktime',
            help='number of kmp block time',
            type=int, default=1)

        self.args = arg_parser.parse_args(self.custom_args, namespace=self.args)

        # Set KMP env vars, if they haven't already been set, but override the default KMP_BLOCKTIME value
        config_file_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), "config.json")
        self.set_kmp_vars(config_file_path, kmp_blocktime=str(self.args.kmp_blocktime))

        set_env_var("OMP_NUM_THREADS", self.args.num_intra_threads)

        script_file = "run_performance.py"
        if self.args.accuracy_only:
            script_file = "run_accuracy.py"
        benchmark_script = os.path.join(
            self.args.intelai_models, self.args.mode, self.args.precision, "brats",
            script_file)

        self.benchmark_command = self.get_command_prefix(args.socket_id) + \
            self.python_exe + " " + benchmark_script

        self.benchmark_command = \
            self.benchmark_command + \
            " --input-graph=" + self.args.input_graph + \
            " --num-inter-threads=" + str(self.args.num_inter_threads) + \
            " --num-intra-threads=" + str(self.args.num_intra_threads) + \
            " --batch-size=" + str(self.args.batch_size) + \
            " --model-name=" + str(self.args.model_name)

        if self.args.onednn_graph:
            self.benchmark_command += "--onednn-graph"

        if not self.args.accuracy_only:
            self.benchmark_command += \
                " --steps=" + str(self.args.steps) + " --warmup-steps=" + str(self.args.warmup_steps)

        # if the data location directory is not empty, then include the arg
        if self.args.data_location and os.listdir(self.args.data_location):
            self.benchmark_command += " --data-location=" + \
                                      self.args.data_location
        if self.args.accuracy_only:
            self.benchmark_command += " --accuracy-only"
            # set up env vars for running accuracy with real data
            set_env_var("nnUNet_preprocessed", "build/preprocessed_data_dir")
            set_env_var("nnUNet_raw_data_base", "build/raw_data")
            set_env_var("DOWNLOAD_DATA_DIR", self.args.data_location)
            set_env_var("RESULTS_FOLDER", "build/result")

    def run(self):
        if self.benchmark_command:
            self.run_command(self.benchmark_command)

            if self.args.output_results:
                print("Inference results file in the output directory: {}".format(self.results_filename))
