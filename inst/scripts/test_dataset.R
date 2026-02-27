## Create sample metadata table for testing validation

## Choosing features to represent all types of feature

## Includes a mix of features that are required/optional and allow/disallow
## multiple values.

## Each feature is supplied with 10 values comprised of both allowed and
## disallowed values.

# corpus.type = any
curator <- c("Jane Doe", "John_Doe", "Jane Doe;John Doe", "Jane Doe|John Doe",
             13, "Adam Bradley", "CathleenDesmond", 0.3335, "Fogsworthy",
             "Gina Hart")
family <- c("Family One", 1, "one", 33, "family B", "thirteen", "f_13", 12, 12,
            "twenty-two")

# corpus.type = binary
antibiotics_current_use <- c("Yes", "no", "y", 1, "2", TRUE, "TRUE", "F", FALSE,
                             "t|f")

# corpus.type = character
feces_phenotype_value <- c(2.844, "type 1", "2.844", 17, 1, "3<;>4", "one", 1.1,
                           12.8, 2222.2222)

# corpus.type = custom_enum
lifestyle <- c("Hunter-gatherer", "Hunter_gatherer", "pastoralist",
               "Pastoralist", "Fisher|Pastoralist", "Farmer", "Agropastoralist",
               "Agriculturalist", "fisher", "Fisher")
neonatal_feeding_method <- c("Mixed Feeding", "Mixed Feeding|No Breastfeeding",
                             "Mixed Feeding;No Breastfeeding",
                             "exclusively_breastfeeding", "formula",
                             "mixed feeding", "Mixed Feeding;Mixed Feeding",
                             "Exclusively Formula Feeding", "No Breastfeeding",
                             "no breastfeeding")
sequencing_platform <- c("IonProton", "IonProton;IlluminaNovaSeq", "illumina",
                         "IlluminaHiSeq", "Illumina Hi Seq", "ionproton",
                         "IlluminaNovaSeq", "NA", "sequencing platform", "none")

# corpus.type = dynamic_enum
disease <- c("Cystic Fibrosis", "autoimmune thrombocytopenia",
             "intestinal polyp", "Colorectal Carcinoma",
             "Cystic Fibrosis;Colorectal Carcinoma",
             "autoimmune thrombocytopenia;intestinal polyp",
             "Cystic Fibrosis;intestinal polyp",
             "Malignant Myoepithelial Cell", "burn", "Africa")
country <- c("Andorra", "andorra", "Belize", "Andorra;Belize",
             "Colorectal Carcinoma", "Turkmenistan", "Western Sahara", "Yemen",
             "turkmenistan", "NA")
target_condition <- c("Cystic Fibrosis", "autoimmune thrombocytopenia",
                      "intestinal polyp", "Colorectal Carcinoma",
                      "Cystic Fibrosis;Colorectal Carcinoma",
                      "autoimmune thrombocytopenia;intestinal polyp",
                      "Cystic Fibrosis;intestinal polyp",
                      "Malignant Myoepithelial Cell", "burn", "Africa")

# corpus.type = integer
pmid <- c(01234567, "01234567", 0123456, 77777777, "22222222;33333333", 3, NA,
          "NA", 76543210, 7654321)
number_reads <- c(120, "120", 36.5, 88888844, 0, NA, "NA", "333;29", 1, "three")

# corpus.type = numeric
neonatal_birth_weight <- c(9, 9.3, 9.33, 19.3, 09.9, 0.81, "9", 7.11111,
                           123890.00, 3.9900)

# corpus.type = regexp
study_name <- c("Thomson_2018", "Thompson_2017b", "walsh2016",
                "Johnson_3344_Helms", "Johnson_3344_Helms_2299",
                "Walsh_2016_Helms2299", "walsh_2016", "Thomson2018",
                "helms2299", "Johnson_2233_9")
subject_id <- c("s1", "subject1", "subject_", 44, "abcdefg", "Subject_2",
                "subject*ls;f", 1, "NA", NA)
Sample_Source_ID <- c("ss1", "sample1", "sample_", 14, "sample1", "Sample_2",
                      "sample*ls;f", 1, "NA", NA)

# corpus.type = static_enum
control <- c("Study Control", "Case", "Not Used", "NA", NA, "Case;Not Used",
             "study_control", "case", "not_used", "study control")
smoker <- c("Smoker (finding)", "Smoker",
            "Non-smoker (finding);Ex-smoker(finding)", "never smoked",
            "(finding)", 0, 1, "Smoker;Ex-smoker", NA, "NA")
sex <- c("Female", "Male", "Female;Male", "F", "M", "female", "male", "f", "m",
         1)

# Create table and write to file
test_dataset <- data.frame(curator = curator,
                           family = family,
                           antibiotics_current_use = antibiotics_current_use,
                           feces_phenotype_value = feces_phenotype_value,
                           lifestyle = lifestyle,
                           neonatal_feeding_method = neonatal_feeding_method,
                           sequencing_platform = sequencing_platform,
                           disease = disease,
                           country = country,
                           target_condition = target_condition,
                           pmid = pmid,
                           number_reads = number_reads,
                           neonatal_birth_weight = neonatal_birth_weight,
                           study_name = study_name,
                           subject_id = subject_id,
                           "Sample Source ID" = Sample_Source_ID,
                           control = control,
                           smoker = smoker,
                           sex = sex,
                           check.names = FALSE)

dir <- system.file("extdata", package = "OmicsMLRepoCuration")
readr::write_csv(test_dataset, file.path(dir, "test_dataset.csv"))
