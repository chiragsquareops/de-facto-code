hold dev Env --> setup proper production env
start with networking part --> full fledge production network
Check the difference between public aurora mdoule and our internal aurora module
To create production app asg --> hold dev
Check for the difference between elastic cache module for internal and public
Create all modules in app.tf ie. 
Keypairs module
SG with modules 
ASG with scaling policies --> (CPU, RAM, ALB request rate)
ALB with access logs
CICD --> with Codepipeline
S3 buckets --> To store artifacts (IAM Roles)
Cloudwatch Alarms
Route 53 Healthchecks
