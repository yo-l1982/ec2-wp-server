# Wordpress server stack.

Create stack with:
```
aws cloudformation create-stack --stack-name your-stack-name --template-body file://$PWD/cloudformation/stack.yml --parameters ParameterKey=DeployPublicKey,ParameterValue="{deploy user public key}" ParameterKey=GithubAccount,ParameterValue="{this github account}" ParameterKey=GithubRepo,ParameterValue="{this github repo}"
```
