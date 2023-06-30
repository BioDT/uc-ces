# test run of model from shell
Rscript run_biodiversity_model.R 5334220 outputs/maps outputs/reports 5
Rscript run_biodiversity_model.R 5410907 outputs/maps outputs/reports 5
Rscript run_biodiversity_model.R 8211070 outputs/maps outputs/reports 5
Rscript run_biodiversity_model.R 2481792 outputs/maps outputs/reports 5
Rscript run_biodiversity_model.R 5285637 outputs/maps outputs/reports 5


docker run -v /outputs:/outputs ces-biodiversity 5334220 outputs/maps outputs/reports 5