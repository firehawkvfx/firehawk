# Defines the default values to initialise vault vars with.

locals {
  defaults = tomap( {
    "network/openvpn_admin_pw": {
      "name": "openvpn_admin_pw",
      "description": "The dynamic password for the admin to configure OpenVPN Access Server (at least 8 characters).",
      "default": "",
      "example_1": "MySecretAdminPassword",
    },
    "network/openvpn_user_pw": {
      "name": "openvpn_user_pw",
      "description": "The dynamic password for the user to establish a vpn connection (at least 8 characters).",
      "default": "",
      "example_1": "MySecretUserPassword",
    }    
  } )
  dev = merge(local.defaults, tomap( {
    "aws/bucket_extension": {
      "name": "bucket_extension",
      "description": "The extension for cloud storage used to label your S3 storage buckets.  MUST BE UNIQUE TO THIS RESOURCE TIER (DEV, GREEN, BLUE). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html",
      "default": "dev.${var.global_bucket_extension}",
      "example_1": "dev.example.com",
      "example_2": "green.example.com",
      "example_3": "dev-myemail-gmail-com"
    },
    "network/private_domain": {
      "name": "private_domain",
      "description": "The private domain name for your hosts.  This is required for the host names and fsx storage in a private network.  Launched Infrastructure will switch between different domains depending on the resource environment for isolation.",
      "default": "dev.node.consul",
      "example_1": "dev.node.consul"
    }
  } ) )
  blue = merge(local.defaults, tomap( {
    "aws/bucket_extension": {
      "name": "bucket_extension",
      "description": "The extension for cloud storage used to label your S3 storage buckets.  MUST BE UNIQUE TO THIS RESOURCE TIER (DEV, GREEN, BLUE). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html",
      "default": "blue.${var.global_bucket_extension}",
      "example_1": "dev.example.com",
      "example_2": "green.example.com",
      "example_3": "dev-myemail-gmail-com"
    },
    "network/private_domain": {
      "name": "private_domain",
      "description": "The private domain name for your hosts.  This is required for the host names and fsx storage in a private network.  Launched Infrastructure will switch between different domains depending on the resource environment for isolation.",
      "default": "blue.node.consul",
      "example_1": "blue.node.consul"
    }
  } ) )
  green = merge(local.defaults, tomap( {
    "aws/bucket_extension": {
      "name": "bucket_extension",
      "description": "The extension for cloud storage used to label your S3 storage buckets.  MUST BE UNIQUE TO THIS RESOURCE TIER (DEV, GREEN, BLUE). This can be any unique name (it must not be taken already, globally).  commonly, it is a domain name you own, or an abbreviated email adress.  No @ symbols are allowed. See this doc for naming restrictions on s3 buckets - https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html",
      "default": "green.${var.global_bucket_extension}",
      "example_1": "dev.example.com",
      "example_2": "green.example.com",
      "example_3": "dev-myemail-gmail-com"
    },
    "network/private_domain": {
      "name": "private_domain",
      "description": "The private domain name for your hosts.  This is required for the host names and fsx storage in a private network.  Launched Infrastructure will switch between different domains depending on the resource environment for isolation.",
      "default": "green.node.consul",
      "example_1": "green.node.consul"
    }
  } ) )
  main = merge(local.defaults, tomap( {
    "aws/installers_bucket": {
      "name": "installers_bucket",
      "description": "The S3 bucket name in the main account to store installers and software for all your AWS accounts.  The name must be globally unique.",
      "default": "software.main.${var.global_bucket_extension}",
      "example_1": "software.main.example.com",
      "example_3": "software-main-myemail-gmail-com"
    },
    "network/private_domain": {
      "name": "private_domain",
      "description": "The private domain name for your hosts.  This is required for the host names and fsx storage in a private network.  Launched Infrastructure will switch between different domains depending on the resource environment for isolation.",
      "default": "main.node.consul",
      "example_1": "main.node.consul"
    }
  } ) )
}