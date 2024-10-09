variable "project_name" {
    type = string
    default = "dashboardApp"
}

variable "zone_id" {
    type = string
}

variable "environment" {
    type = string
    default = "dev"
}

variable "dataSourceName" {
    type = string
    default = "exampleds"
}

variable "vpc_cidr" {
    type = string
}

variable "dev_allowed_ips" {
    type = list
}

variable "provisioned_datasets" {
    type = map(any)
    default = {
        provisionedAcmSslEmailValidated = {
            hash_key = "serial",
            attributes = [
                {
                    name = "serial"
                    type = "S"
                }
            ]
        }
    }
}

variable "lambda_functions" {
    type = map(any) 
    default = {
        writeDataToDynamodb = {
            lambda_name = "writeDataToDynamodb",
            path = "writeDataToDynamodb",
            method = "POST",
            integration_type = "AWS_PROXY",
            integration_http_method = "POST",
            querystring = ""
            timeout = "900"
            memory_size = "128"
            runtime = "python3.10"
            handler = "lambda_handler"
        }
        fetchDataFromDynamodb = {
            lambda_name = "fetchDataFromDynamodb",
            path = "fetchDataFromDynamodb",
            method = "POST",
            integration_type = "AWS_PROXY",
            integration_http_method = "GET",
            querystring = ""
            timeout = "30"
            memory_size = "128"
            runtime = "python3.10"
            handler = "lambda_handler"
        }
        fetchDataColumns = {
            lambda_name = "fetchDataColumns",
            path = "fetchDataColumns",
            method = "POST",
            integration_type = "AWS_PROXY",
            integration_http_method = "GET",
            querystring = ""
            timeout = "30"
            memory_size = "128"
            runtime = "python3.10"
            handler = "lambda_handler"
        }
        fetchDataMetadata = {
            lambda_name = "fetchDataMetadata",
            path = "fetchDataMetadata",
            method = "POST",
            integration_type = "AWS_PROXY",
            integration_http_method = "GET",
            querystring = ""
            timeout = "30"
            memory_size = "128"
            runtime = "python3.10"
            handler = "lambda_handler"
        }
    }
}
