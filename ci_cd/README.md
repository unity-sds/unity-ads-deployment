<!-- Header block for project -->
<hr>

<div align="center">

<!-- ☝️ Replace with your logo (if applicable) via ![](https://uri-to-your-logo-image) ☝️ -->
<!-- ☝️ If you see logo rendering errors, make sure you're not using indentation, or try an HTML IMG tag -->

<h1 align="center">U-ADS Deployment</h1>
<!-- ☝️ Replace with your repo name ☝️ -->

</div>

<pre align="center">Terraform based deployment of the U-ADS infrastructure into MCP-AWS</pre>

<!-- Header block for project -->

<!-- ☝️ Add badges via: https://shields.io e.g. ![](https://img.shields.io/github/your_chosen_action/your_org/your_repo) ☝️ -->

<!-- ☝️ Screenshot of your software (if applicable) via ![](https://uri-to-your-screenshot) ☝️ -->

The Unity Algorithm Development Services (U-ADS) Auto Clone/Build (ACB) infrastructure brings together several tools and resources to enable cloning and building a git project to the Unity specifications. This software encapsulates and automates the deployment of most of the U-ADS infrastructure into an MCP AWS enclave. It consists of Terraform and Bash scripts for GitLab CI/CD service, and it can deploy U-ADS ACB into any of the three Unity Dev, Test, and Prod accounts (venues).

This README file briefly explaines what resources the deployment creates, and what preexisting reosurces it depends on. It covers just enough information to help with a successful deployment of the U-ADS ACB into the cloud. For details on the design of the ACB system, testing the system, and troubleshooting the reader is encouraged to read _MCP Cloning 20240722_ Word document (or a later version if it exists) at [Unity Project > Work Areas > Algorithm Development Services > Documentation](https://drive.google.com/drive/folders/15kWfQw0R9i-OdJjYNGmGa3iAn8dQXv4K?ths=true). This link is a folder where the docuemnt is located and not a link to the document itself. The document is referenced a few times in this README file, and hereafter it is referenced as _MCP Cloning_ document.

<!-- example links>
[Website](INSERT WEBSITE LINK HERE) | [Docs/Wiki](INSERT DOCS/WIKI SITE LINK HERE) | [Discussion Board](INSERT DISCUSSION BOARD LINK HERE) | [Issue Tracker](INSERT ISSUE TRACKER LINK HERE)
-->

## Deployed Resources

The resources deployed by this software are mostly AWS resources, and they are

* EC2 Instance
* Security Group
* Lambda function and layer
* CloudWatch log group
* Secret at AWS Secrets Manager
* Lambda execution role and its policies 
* Restful API method for calling the Lambda function
* Unity-App-Build-Trigger https://github.com/unity-sds/unity-app-build-trigger (not an AWS resource, but installed by this package in the EC2 Instance)
* gitlab runners (not an AWS resource, but installed and run by this package in the EC2 Instance)

## Dependencies

The successful deployment of the above mentioned resources depends on the existance of the following resources, which are mostly AWS resources:

* VPC: Unity-\<_Venue_\>-VPC
* Private Subnet(s): Unity-\<_Venue_\>-Priv-Subnet\<_dd_\>
* MCP Provided IAM Boundary Policy: mcp-tenantOperator-AMI-APIG
* AWS Provided IAM Policy: AWSLambdaBasicExecutionRole
* AWS Provided IAM Policy: AWSXRayDaemonWriteAccess
* API Gateway (rest API): Unity API Gateway
* API Gateway Authorizer, attached to Unity API Gateway
* A gitlab instance, which currently is MCP GitLab Ultimate (not an AWS resource)

where

* \<_Venue_\> is replaced with Dev, Test, or Prod, depending on which Unity account is being used
* \<_dd_\> is replaced with two decimal digits like 01, 02, or 03.

## GitLab 

### Instance

This software does not deploy any gitlab instance.  Currently, Unity project uses MCP (Mission Cloud Platform) GitLab provided by Goddard for its git repository management. The MCP GitLab URL is https://gitlab.mcp.nasa.gov.  To request an MCP GitLab lisence, follow the instructions at
[Requesting Access to GitLab Ultimate](https://caas.gsfc.nasa.gov/display/GSD1/Requesting+Access+to+GitLab+Ultimate)
and choose “Project Owner” for the “Gitlab Role”.

### Runners

As a part of U-ADS ACB deployment, this terraform/bash software deploys gitlab runner in U-ADS ACB EC2 Instance and registers it at MCP GitLab. The registeration requires MCP GitLab registeration token, which can be obtained from https://gitlab.mcp.nasa.gov. Terraform prompts for entering the token during '_terraform apply_'.

### Registration Token

Gitlab executor registration process requires a registration token.  This software defines the variable

* _gl_runner_registration_token_

for entering the current registration token.  To see the token at MCP GitLab
1. Log in to MCP GitLab
2. Starting from the left side-bar, go to
   * Left side-bar  >  Groups  >  Unity
3. After accessing Unity Group and again starting from left side-bar, go to
   * Build  >  Runners
4. On the right side of the location above the area where registered executors are listed, there is a _New group runner_ button, and to the right of the button there is a small menue with three vertical dots '.'. Click on the dots, and you will see the hidden regiteration token.
5. click on the eye icon to see the registration token

The registration token can be reset at this same location.

## U-ADS ACB Deployment

This section explaines how to deploy U-ADS ACB into Unity _Dev_ account (venue) in MCP cloud. The deployment into Unity _Test_ and _Prod_ accounts are also done the same way. Just replace any occurence of _Dev_ with either _Test_ or _Prod_.

### Requirements

The deployment of the U-ADS ACB depends on some preexisting resources, which were covered in Section _Dependencies_. However, there are other requirements which need to be met before a successful deployment. Please, keep in mind that the requirements covered in this README file are only for U-ADS ACB deploument and not for cloning and building a project (using U-ADS ACB). Document _MCP Cloning_ covers the requirements for a successful use of U-ADS ACB. The remaining requirements for a successful deployment are

* _MCP user account_: This account grants access to https://login.mcp.nasa.gov/.
* _MCP GitLab account_: This account grants access to https://gitlab.mcp.nasa.gov/.
* _MCP registration token for GitLab executors_: Section _GitLab_ of this README file explaines how to obtain the registration token for MCP GitLab.
* _Trigger token for [Unity-MCP-Clone](https://gitlab.mcp.nasa.gov/unity/unity-mcp-clone)_: This is the trigger token for https://gitlab.mcp.nasa.gov/unity/unity-mcp-clone git project, which can be accessed after logging into MCP GitLab.

### Deployment Steps

Follow these steps to deploy U-ADS ACB (commands in _italic_):
1. Download the software for automated U-ADS ACB deployment by entering the command
   * _git clone https://github.com/unity-sds/unity-ads-deployment_
2. Create a file named _mcp_glu_secrets.json_ that contains three secret values, which are MCP GitLab account user ID, MCP GitLab account access token, and trigger token for [Unity-MCP-Clone](https://gitlab.mcp.nasa.gov/unity/unity-mcp-clone) pipeline. The json file must reside in _unity-ads-deployment/ci_cd/policies_ subdirectory. In the same subdirectory, there already exists a template file, which can be used to create the desired json file. To create the file, do the following
   * _cd unity-ads-deployment/ci_cd/policies_
   * _cp mcp_glu_secrets.json.incomplete mcp_glu_secrets.json_
   * Open the file _mcp_glu_secrets.json_ populate it with the missing values, i.e. replace each occurance of <*> in the file with an appropriate value.
3. Use your MCP user account credentials to log into https://login.mcp.nasa.gov/ and obtain short term access tokens for Unity Dev account, then set the tokens as shell environment variables in a terminal from where you want to deploy U-ADS ACB.
4. Now, you should be able to deploy U-ADS ACB into MCP cloud from the same terminal where you set the MCP cloud short term access tokens. Enter the following command:
   * _cd unity-ads-deployment/ci_cd/Dev_
   * _terrafrom init_
   * _terraform apply_

After entering the commnad _terraform apply_, first you are prompted to enter the gitlab runner registration token, then you are prompted to confirm the deployment by entring _yes_.

### Unity API Gateway Deployment and Stage

Intentionally, a portion of U-ADS ACB deployment is not automated and msut be done manually. After U-ADS ACB is successfully deployed, log into https://login.mcp.nasa.gov/ and access MCP/AWS console for Unity _Dev_ account. Then navigate to _Unity API Gateway_ (please see Section _Dependencies_) and deploy the API Gateway by clocking on __Deploy API__. For stage, choose '_dev_'.

### What to Expect

After entering _terraform aaply_ command and a coffee break, because time is needed for a full U-ADS ACB system initialization, there are a few things that you can check to make sure the ACB system is deployed correctly:
   * GitLab runner
   * some AWS resources
   * loging into the EC2 instance

#### GitLab Runner

The registered runner will appear at the Unity group CI/CD.  To see the registered runner
1. Log into MCP GitLab at https://gitlab.mcp.nasa.gov/
2. From the left sidebar select _Groups_
3. Then select _Unity_ group
4. Again, from the left sidebar select _Build > Runners_

You should be able to see a recently registerd runner with three tags _shell, unity, dev_.

#### AWS Resources

Log into https://login.mcp.nasa.gov/ and access Unity _Dev_ account AWS console. The following is a list of some AWS resources that you should be able to find after a successful U-ADS ACB deployment:
   * AWS Secrets Manager > Secrets > __MCP-GLU-Clone__
   * VPC > Security Groups > __GitLab Runner Security Group__
   * EC2 > Instances > __unity-ads-gl-runner-shell__
   * IAM > Roles > __Lambda-Exec--Unity-ADS--MCP-Clone__
   * Lambda > Functions > __Unity-ADS--MCP-Clone__

#### Logging into the EC2 Instance

After a successful U-ADS ACB deployment, you should be able to log into _unity-ads-gl-runner-shell_ EC2 insance. Log into https://login.mcp.nasa.gov/ and access Unity _Dev_ account AWS console. Navigate to _EC2 > Instances_, then select _unity-ads-gl-runner-shell_ and click on _Connect_ button close to the top of the page, which will take you to a new page. Then select _Session Manager_ and another _Connect_ button at the lower right corner of the new page. A "terminal" appears with a shell prompt, and you are logged into the EC2 instance. At this point, you should be able to enter the following command and switch to _gitlab-runner_ account:
   * _sudo su - gitlab-runner_

At the home directory of _gitlab-runner_ account, you should find the git project _unity-app-build-trigger_ installed.

## U-ADS ACB Destruction

This section explaines how to destroy U-ADS ACB system already deployed into Unity _Dev_ account (venue) in MCP cloud. The destruction of the system in Unity _Test_ and _Prod_ accounts are also done the same way. Just replace any occurence of _Dev_ with either _Test_ or _Prod_.

Follow these steps to destroy U-ADS ACB (commands in _italic_):
1. Use your MCP user account credentials to log into https://login.mcp.nasa.gov/ and obtain short term access tokens for Unity Dev account, then set the tokens as shell environment variables in a terminal from where you want to destroy U-ADS ACB system.
2. Now, you should be able to destroy U-ADS ACB in MCP cloud Unity _Dev_ account from the same terminal where you set the MCP cloud short term access tokens. Enter the following command:
   * _cd unity-ads-deployment/ci_cd/Dev_
   * _terrafrom destroy_

The first prompt, after entering the command _terrafrom destroy_, can be ignored, and you just press the _return_ key. The second prompt expects the confirmation of the U-ADS ACB system distruction, and you enter _yes_.

### Important Notes

#### GitLab Runner

Ideally, the command _terrafrom destroy_ should unregister the GitLab runner registered at MCP GitLab during _terraform apply_; however, the Terraform automation cannot unregister the runner. At the time of the development of this deployment automation software, MCP did not permit EC2 Instance access via _ssh_ for security reasons. The only method for automatic unregistraion of the runner, that the original developer of this automation system was able to find,  required _ssh_ access to the EC2 instance. A future developer should look into this and see whether or not there are ways to implement the automated runner unregistration.

It is not necessary to worry about the elimination of the useless runners, that are left behind after _terraform destroy_ commands; however, the person who maintains this system should log into MCP GitLab at https://gitlab.mcp.nasa.gov/ occasionally, access Unity group runners, and delete the suspended or inactive runners.

#### _MCP-GLU-CLONE_ Secret

By default, AWS does not immediately destroy an _AWS Secrets Manager_ secret upon a destruction request, and the secret gets scheduled for destruction after a grace period, which is usually several days. The U-ADS ACB system deployment Terraform script sets the destruction grace period for _MCP-GLU-Clone_ secret to zero (0); therefore, it should be deleted immediately during _terraform destroy_. However, if the secret is not destroyed immediately during _terraform destroy_, then the following AWS CLI command will destroy is immediately:
   * _aws secretsmanager delete-secret --secret-id MCP-GLU-Clone --force-delete-without-recovery --region us-west-2_

It is important to make sure the secret is deleted before the next _terraform apply_; otherwise, the next deployment attempt will fail.
