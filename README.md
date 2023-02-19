#  ADEduKitTool

## General

ADEduKitTool is an app to update classkit activities in the Apple ClassKit Catalog database. 
This database is consulted by Schoolwork app for activities from apps, which are not installed on the device.

The main difference between classkit management in an app and the tool via the Catalog API, is that outside the app multiple locales are to be managed as well as additional metadata, which is implicit in the app.

The Tool in general supports multiple model files, but the currently active model has to be selected at compile time.
When the Tool is started, the user can select between environments "development" for testing and "production" for the actual live data and one of the locales, which were detected in the model.

Actions exist to get, put and delete individual model items as well as all model items.

## Configure Secrets

You need to provide your credentials for using the ClassKit Catalog API.
These should be put into a file `Secret.swift` in directory `_Secret`.
This directory contains a `.gitignore` file, which basically excludes all files from source control.
You can copy `_SecretTmpl/SecretTmpl.swift` to `_Secret/Secret.swift`.
Change references to `SecretTmpl` to `Secret` in the `ClassKitClient` class.

## TODO

- implement thumbnail support
- support metadata.minimumBundleVersion
- create a "publishing log report"
- create a "currently published data report"

## UI Design

- Operations
    - select data model (use listeners for change)
    - select environment (use listeners for change)
    - select locale (use listeners for change)
    - choose from single or batch operation mode
    - get, put, delete (data model should support listener change)
- Info Presentation
    - list of ids
    - with network status for operations
- Reports
    - all data for all ids of a model
    - html page?
- Screens
    - select environment
    - select locale
    - select model
    - id list
    - id summary
    - model summary
        - list of ids
    - item details
        - all properties etc.
    - dashboard
        - models
        - op status
        - locale summary

## Project Structure

- AppDelegate = standard
- SceneDelegate = standard
- ViewController = initial view controller
    - viewDidLoad
        - configure environment to be "development"
        - load the adedukit model
        - build a model list
        - load model metadata
