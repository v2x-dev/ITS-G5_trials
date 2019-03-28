# Google Maps API Key
Our scripts provide the functionality of plotting our experimental results on real-world maps, downloaded from Google. 

To do so, an API key is required from **_"plot_google_map"_** function, already included under the **_"./+src/+plotGoogleMap/"_** folder. To acquire an API key, the steps under this link should be followed:
[Google Maps Platform: Get API Key](https://developers.google.com/maps/documentation/javascript/get-api-key#step-2-add-the-api-key-to-your-request)

When the API key is aquired, it should be **saved in the *"./apiKey/"*** folder as a MAT file. The name of the file should be **_"api_key.mat"_**.

**_IMPORTANT_**: The use of an API key is **optional**. The results can still be processed and generated using the provided scripts. They will be plotted as Matlab figures, without though having a map as the background. The added functionality of *"plot_google_map"* is that a map can be plotted as a background in an existing figure. 

Many thanks to Zohar Bar-Yehuda, for providing the *"plot_google_map"* function. More information about that, as well as the code, can be found under [this](https://uk.mathworks.com/matlabcentral/fileexchange/27627-zoharby-plot_google_map) link.
