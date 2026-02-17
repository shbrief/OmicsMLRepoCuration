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
antibiotics_current_use <- c("Yes", "no", "y", 1, "2", true, "TRUE", "F", FALSE,
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
disease
country
target_condition

# corpus.type = integer
pmid
number_reads

# corpus.type = numeric
neonatal_birth_weight

# corpus.type = regexp
study_name
subject_id

# corpus.type = static_enum
control
smoker
sex
