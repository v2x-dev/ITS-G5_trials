# ITS-G5 Trials - Repository for the scripts to parse and process our experimental dataset

These scripts can be used to process the data from our ITS-G5 city-scale car trials. Our dataset, where we recorded all the network interactions between our experimental devices, can be found under the [link](https://doi.org/10.5523/bris.eupowp7h3jl525yxhm3521f57).

More specifically, our scripts can parse all the dataset files, and generate three *.log* files per-device. The first file refers to the transmitted, and the other two files refer to the received ETSI's ITS-G5 CAMs. More information about the generated *.log* files can be found in our paper *"A Dataset of Full-Stack ITS-G5 DSRC Communications over Licensed and Unlicensed Bands Using a Large-Scale Urban Testbed"* [link](https://arxiv.org/abs/1903.10289).

To make it possible to manipulate our dataset with a reduced memory footprint, the raw data are further filtered into MATLAB data files. These Matlab files are saved under the directory *./<raw_data_main_folder>/importedData*, can be later used for our performance investigation. To do so, a collection of scripts is provided *(scriptsResults)* that can generate all the results from our work.

# Licence
This code is freely available under the GNU General Public License v3.0, found in the [LICENCE](https://github.com/v2x-dev/multithread-inet/blob/master/LICENSE) file.\
If this code is used for drafting a manuscript, we ask the authors to cite the following paper:

```    
@ARTICLE{dataInBrief,
       author = {I. Mavromatis, and A. Tassi and R. J. Piechocki},
        title = {{A Dataset of Full-Stack ITS-G5 DSRC Communications over Licensed and Unlicensed Bands Using a Large-Scale Urban Testbed}},
      journal = {arXiv e-prints},
         year = "2019",
        month = "Mar",
       eprint = {1903.10289},
       note ="[Online]. Available:~\url{https://arxiv.org/abs/1903.10289}",
}
```

# Requirements
Our scripts have been tested and are compatible with MATLAB R2017b or later. Older Matlab versions should work as well but they were not tested.

To process the PCAP traces in our dataset, a modified version of Tcpdump is required. This version can be found under our repository:
[https://github.com/v2x-dev/tcpdump](https://github.com/v2x-dev/tcpdump)

# Google Maps API Key
Our scripts provide the functionality of plotting our experimental results on real-world maps, downloaded from Google. To do so, an API key is required by the **_"plot_google_map"_** function, located in **_"+src/+plotGoogleMap/"_** folder. More information about that functionality can be found under this [link](https://github.com/v2x-dev/ITS-G5_trials/blob/master/apiKey/README.md). For the generation of the results the API key is not mandatory.

# How to Use it
1. Download all the scripts from our [repository](https://github.com/v2x-dev/ITS-G5_trials).
2. Download the dataset from our [Research Data Storage Facility](https://doi.org/10.5523/bris.eupowp7h3jl525yxhm3521f57).
3. Download, compile and install our modified [Tcpdump](https://github.com/v2x-dev/tcpdump) version. For more information, please refer to Tcpdump documentation. 
4. Open *"dataProcess.m"* file, from the repository's main folder and modify:
a. Add the path to the raw dataset modifying *"origPath"* variable.
b. Add the path to the modified Tcpdump version modifying *"tcpdumpPath"* variable.
5. Run *"dataProcess.m"* script to process all the raw data and generate the MAT files in the *"./<raw_data_main_folder>/importedData"* folder.
6. To generate all the figures related with our work, open the three scripts inside *"scriptResults"* folder and modify the variable *"pathRoot"*. This variable should point out in the *"./<raw_data_main_folder>/importedData"*. Then, all the scripts are ready to be executed.

Steps 1-5 can be skipped, if the user decides to use our pre-processed MAT files (found in our [dataset]((https://doi.org/10.5523/bris.eupowp7h3jl525yxhm3521f57))).

# Useful Links
More information about Tcpdump can be found in [Tcpdump website](https://www.tcpdump.org).
More information about ETSI's ITS-G5 protocol stack can be found in [ETSI TS 102 636-3 technical specification](https://www.etsi.org/deliver/etsi_ts/102600_102699/10263603/01.01.01_60/ts_10263603v010101p.pdf).
More information about ETSI's ITS-G5 CAMs can be found in [ETSI EN 302 637-2 technical specification](https://www.etsi.org/deliver/etsi_EN/302600_302699/30263702/01.03.01_30/en_30263702v010301v.pdf).
