---
title: "Exploring the Overlays Capture Architecture: Managing Data Captured from Temperature Sensors"
date: 2023-01-29T19:27:05+02:00
layout: post
authors:
 - mo
tags:
 - oca
comments: true
---

This article will look at how to parse OCA (Overlays Capture Architecture) from an Excel template and convert it into OCA Bundle, a zip archive file. We will also describe the files included in the zip archive and show how to read the meta.json file. Additionally, we will demonstrate how to verify the integrity of the OCA Bundle and validate the captured data. Finally, we will look at transforming the units of captured data from Celsius to Kelvin. By the end of this article, you will have a better understanding of the OCA system and how to work with OCA data.

## Prerequisites
To follow described OCA exploration, you will need the OCA Bundle file. To get one, you can:
 - generate it from the XLS template. To do this, download the prepared [oca_bundle.xlsx](https://data-vault.argo.colossi.network/api/v1/files/EsWbDUorzNF1wv2cryD_fToNDhax7APLVN3Q2EAxeqRU) file with defined OCA for capturing data from a temperature sensor. Then, the [OCA Parser](https://oca.colossi.network/ecosystem/oca-parser.html) is used to convert the XLS file into OCA Bundle as a zip archive. The command to do this is:
    `./parser parse oca -p ./oca_bundle.xlsx --zip`
- [download](https://data-vault.argo.colossi.network/api/v1/files/EukCvvhAim2elMtOMMIs3bwPf4fbvQzZswl3TyEGaNrA) pre-generated OCA Bundle file directly

In either case, once you have obtained an OCA Bundle, you can begin exploring the structure and contents of the bundle and working with the data contained in it.

## Under the hood
Let's see what the generated zip archive contains:
`unzip -l oca_bundle.zip`
This will produce output similar to the following:
```bash
Archive:  oca_bundle.zip
  Length      Name
---------   ----
      190   EmL-JD22a1RywPXzzZLAEOxR8NHSi-04pQnOhNwHG7sg.json
      277   EmYQZgAnoE_AIsOiZHL17jw7KGnYgY1pPRFfSUnVYUj0.json
      213   EATuKGoJosYKLyLvdNBXpFM2YeuKuzvthOHu08whWWmA.json
      275   meta.json
---------   -------
      955   4 files
```
The zip archive contains several JSON-formatted files, including overlays and capture base files, that comprise the OCA Bundle. Furthermore, there is a `meta.json` file, a JSON-formatted file containing information about the other files in the zip archive. This file can be used to navigate through the OCA Bundle and access the overlays and other data collected in the archive.

## Reading the meta.json file
`cat meta.json` will produce the following output:
```json
{
  "files": {
    "EmL-JD22a1RywPXzzZLAEOxR8NHSi-04pQnOhNwHG7sg": {
      "character_encoding": "EmYQZgAnoE_AIsOiZHL17jw7KGnYgY1pPRFfSUnVYUj0",
      "unit": "EATuKGoJosYKLyLvdNBXpFM2YeuKuzvthOHu08whWWmA"
    }
  },
  "root": "EmL-JD22a1RywPXzzZLAEOxR8NHSi-04pQnOhNwHG7sg"
}
```
The `files` attribute is a JSON object that maps the names of the overlays, bounded to capture base defined by a unique identifier (SAI) as key, and files to the SAI of the file within the OCA Bundle.

The `root` value references the top-level `capture_base` in the OCA Bundle. This `capture_base` is the starting point for traversing OCA when it contains attributes that refer to other OCAs, but it's not covered in this article. If you are interested in investigating this topic further, you can read more about [reference attribute type](https://oca.colossi.network/specification/#attribute-type) in the OCA documentation.

## Verify OCA Bundle Integrity
The following code examples demonstrate how to verify the integrity of an OCA Bundle, a zip archive containing data captured by the Overlays Capture Architecture (OCA) system. 

JavaScript:
```javascript
import { Validator } from 'oca.js'
import { resolveFromZip } from 'oca.js-form-core'

const oca = await resolveFromZip(ocaBundleFile)
const validator = new Validator()
validator.validate(oca) // { success: boolean, errors: string[] }
```
Rust:
```rust
use oca_rust::state::{oca::OCA, validator::{Validator, Error}};
use oca_zip_resolver::resolve_from_zip;

let oca = resolve_from_zip("path/to/oca_bundle.zip")?;
let validator = Validator::new();
validator.validate(&oca); // Result<(), Vec<Error>>
```
The code uses the `resolveFromZip` method to load the OCA Bundle from the file system. This function returns an [OCA object](#OCA-object-with-Form-and-Credential-overlays-ignored) representing the OCA data in the zip archive. Then creates a `Validator` object to perform the validation. The `validate` method of the `Validator` is then called on the OCA object to perform the validation.

In the JavaScript example, the `validate` method returns an object with a `success` property, which indicates whether the validation was successful, and an `errors` property, which is an array of error messages if the validation failed.
In the Rust example, the `validate` method returns a `Result` object, with `Ok` if the validation was successful, or `Err` with a vector of `Error` objects if the validation failed.

In both cases, the `Validator` object checks the OCA Bundle for any inconsistencies or errors, such as missing or invalid overlays, and returns information about any issues it finds. It allows users to ensure that the OCA Bundle is valid and can be used for accessing and analyzing the data.

## Validating Captured Data

To validate the captured data, you need to use a tool like the [OCA Data Validator](https://oca.colossi.network/ecosystem/oca-validator.html). This tool allows you to check that the data in a CSV file conforms to the structure and format defined in an OCA Bundle.

To use the OCA Data Validator, you first need to [download](https://data-vault.argo.colossi.network/api/v1/files/E3AP34Xxh9zcAwwuw_zo4ixDCdoVHj3ML4LX5CwwF_8s) an example data file in CSV format. This file contains multiple rows of data, with each row representing a temperature measurement at a specific timestamp.
```
timestamp,temperature
1607005200,22.7
1607005260,22.8
1607005320,22.9
1607005380,22.7
1607005440,22.8
...,...
```
Once you have downloaded the data file, you can use the OCA Data Validator to check that the data in the file conforms to the OCA Bundle. To do this, you must create a Validator instance, set the validation constraints, and then run the validation process on the data.

Both the JavaScript and Rust examples below show how to do this. The code creates a Validator instance, sets the validation constraints, and checks that the data in the CSV file conforms to the OCA bundle. If any issues are found, an error will be returned.

JavaScript:
```javascript
const { Validator, CSVDataSet } = require('oca-data-validator')
const { resolveFromZip } = require('oca.js-form-core')
const csv = require('csvtojson')

const oca = await resolveFromZip(ocaBundleFile)
const validator = new Validator(oca)
validator.setConstraints({ failOnAdditionalAttributes: true })

const data = await csv().fromFile('path/to/data.csv')
validator.validate(data)
```
Rust:
```rust
use oca_conductor::{
    Validator,
    validator::ConstraintsConfig,
    data_set::CSVDataSet
};
use oca_zip_resolver::resolve_from_zip;

let oca = resolve_from_zip("path/to/oca_bundle.zip")?;
let mut validator = Validator::new(oca);
validator.set_constraints(ConstraintsConfig {
    fail_on_additional_attributes: true,
});

let file_path = std::path::Path::new("path/to/data.csv");
let file_contents = std::fs::read_to_string(file_path)?;

validator.add_data_set(
    CSVDataSet::new(file_contents.to_string())
        .delimiter(',')
);

validator.validate(); // Result<(), Vec<ValidationError>>
```
In the JavaScript code, the `oca-data-validator` and `oca.js-form-core` packages are used to create a Validator instance and resolve the OCA Bundle. The `csvtojson` package is used to parse the CSV file into a JSON object, which is then passed to the `validate` method on the `Validator` instance to validate the data against the OCA Bundle.

In the Rust code, the `oca_conductor` and `oca_zip_resolver` crates are used to create a `Validator` instance and resolve the OCA Bundle. The `std::fs` module reads the CSV file's contents into a String, which is then passed to the `add_data_set` method on the `Validator` instance. The `validate` method is called on the `Validator` instance to validate the data against the OCA Bundle.

## Transforming Units: Converting from Celsius to Kelvin
Transforming units is a common task when working with data captured by sensors. In the case of temperature data, it may be necessary to convert from one unit of measurement to another. For example, you may need to convert from Celsius to Kelvin or vice versa.

The following code demonstrates how to use the [OCA Data Transformer](https://oca.colossi.network/ecosystem/oca-transformer.html) to convert the units of captured data from Celsius to Kelvin.
```javascript
const fs = require('fs')
const { Transformer, CSVDataSet } = require('oca-data-transformer')
const { resolveFromZip } = require('oca.js-form-core')

const data = fs.readFileSync('data.csv', 'utf8');
const delimiter = ','
const oca = await resolveFromZip(ocaBundleFile)

const transformer = new Transformer(oca)
  .addDataSet(new CSVDataSet(data, delimiter))
  .transform([`
{
  "attribute_units": {
    "temperature": "K"
  },
  "capture_base": "E1ZVGMTH-A-E4jJ5HDM7Lkpwz822Fs4Sa4HNol7oGY9M",
  "metric_system": "SI",
  "type": "spec/overlays/unit/1.0"
}
  `])

transformer.getRawDatasets()
```
The code reads the data from a CSV file called `data.csv` using the `fs` module and stores the data in a variable called `data`. The code also sets a delimiter for the CSV data, specifying the character used to separate the values in each row. In this case, the delimiter is a comma.

The code then uses the `resolveFromZip` function from the `oca.js-form-core` package to read the OCA Bundle from the specified zip archive file.

Next, the code creates a new `Transformer` instance and adds the `CSVDataSet` instance that was created earlier to the transformer. The `Transformer` instance is then used to transform the data in the OCA Bundle. In this case, the transformation is specified using a Unit overlay that defines the attribute units to be used for the temperature data (in this case, Kelvin).

Finally, the code calls the `getRawDatasets` method on the `Transformer` instance to retrieve the transformed data. This method returns the transformed data as an array of datasets, which can be accessed and used as needed.

## Conclusion and Next Steps
The OCA Bundle provides a number of benefits over more traditional methods of representing data. It enables the data from different sensors and devices to be easily combined and shared with other applications or systems, which can help to improve the interoperability and usefulness of the data. Additionally, the OCA Bundle provides a consistent and well-defined structure for representing sensor data, which can make it easier for developers to work with the data in their applications.

There are many ways to continue exploring OCA and working with OCA data. One possible next step is to look at the [OCA specification](https://oca.colossi.network/specification/) in more detail and learn more about the different elements of OCA. Another potential direction is to experiment with different ways of accessing and working with OCA data, such as using the [oca.js](https://www.npmjs.com/package/oca.js) library, [oca-rust](https://crates.io/crates/oca-rust) crate or other [tools](https://oca.colossi.network/ecosystem/tour.html) and libraries that support OCA. Finally, you could explore the use of OCA in real-world applications, such as IoT systems or other scenarios where data is collected and shared. Regardless of which direction you choose to take, OCA provides a powerful and flexible framework for managing and working with data.


## Appendix
#### OCA object (with Form and Credential overlays ignored):
```json
{
  "capture_base": {
    "attributes": {
      "temperature": "Numeric",
      "timestamp": "Text"
    },
    "classification": "",
    "digest": "EmL-JD22a1RywPXzzZLAEOxR8NHSi-04pQnOhNwHG7sg",
    "flagged_attributes": [],
    "type": "spec/capture_base/1.0"
  },
  "overlays": [
    {
      "attribute_character_encoding": {
        "temperature": "utf-8",
        "timestamp": "utf-8"
      },
      "capture_base": "EmL-JD22a1RywPXzzZLAEOxR8NHSi-04pQnOhNwHG7sg",
      "default_character_encoding": "utf-8",
      "digest": "EmYQZgAnoE_AIsOiZHL17jw7KGnYgY1pPRFfSUnVYUj0",
      "type": "spec/overlays/character_encoding/1.0"
    },
    {
      "attribute_units": {
        "temperature": "C"
      },
      "capture_base": "EmL-JD22a1RywPXzzZLAEOxR8NHSi-04pQnOhNwHG7sg",
      "digest": "EATuKGoJosYKLyLvdNBXpFM2YeuKuzvthOHu08whWWmA",
      "metric_system": "nonSI",
      "type": "spec/overlays/unit/1.0"
    }
  ]
}
```

