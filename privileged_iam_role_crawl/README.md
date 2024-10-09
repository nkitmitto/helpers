# Privileged IAM Role Crawler
This is a quick script that was written to crawl every IAM role in an account and scan for specific permissions. You can add/remove permissions you're looking for in the "permissionsToScanFor" array.

This tool is assuming you have CLI access to the account you want to scan.

Future iterations, I want to have this read the Organization owner and crawl every AWS account in the AWS Organization.
