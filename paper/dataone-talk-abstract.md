
Content-based Identifiers for Iterative Forecasts: a proposal

Iterative forecasts pose particular challenges for archival data storage and retrieval.  In an iterative forecast, data about the past and present must be downloaded and fed into an algorithm that will output a forecast data product.  Previous forecasts must also be scored against the realized values in the latest observations. Content-based identifiers provide a convenient way to consistently identify input and outputs and associated scripts.  These identifiers are: 
(1) location agnostic -- they don't depend on a URL or other location-based authority (like DOI)
(2) reproducible -- the same data file always has the same identifier
(3) frictionless -- cheap and easy to generate with widely available software, no authentication or network connection
(4) sticky -- the identifier cannot become unstuck or separated from the content
(5) compatible -- most existing infrastructure, including DataONE, can quite readily use these identifiers

I illustrate an example iterative forecasting workflow. In the process, I highlight some newly developed
R packages for making this easier.


