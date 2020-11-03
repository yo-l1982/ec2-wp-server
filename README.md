# Wordpress server stack.

Create stack with:
```
aws cloudformation create-stack --stack-name your-stack-name --template-body file://$PWD/cloudformation/stack.yml --parameters ParameterKey=DeployPublicKey,ParameterValue="{deploy user public key}" ParameterKey=GithubAccount,ParameterValue="{this github account}" ParameterKey=GithubRepo,ParameterValue="{this github repo}"
```

## Required Parameters
Add to create command as such `ParameterKey=ParameterName,ParameterValue="Value"`

- GithubRepo 
- GithubAccount 
- DeployPublicKey 

## Optional Parameters
Add to create command as such `ParameterKey=ParameterName,ParameterValue="Value"`

- InstanceType 
- VolumeSize 
- EC2KeyName 