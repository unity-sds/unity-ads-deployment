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
	https://caas.gsfc.nasa.gov/display/GSD1/Requesting+Access+to+GitLab+Ultimate
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

## U-ADS ACB Deployment in Brief

This section explaines how to deploy U-ADS ACB into Unity _Dev_ account (venue) in MCP cloud. The deployment into Unity _Test_ and _Prod_ accounts are also done the same way. Just replace any occurence of _Dev_ with either _Test_ or _Prod_.

### Requirements

The deployment of the U-ADS ACB depends on some preexisting resources, which were overed in Section _Dependencies_. However, there are other requirements which need to be met before a successful deployment. Please, keep in mind that the requirements covered in this README file are only for U-ADS ACB deploument and not for cloning and building a project (using U-ADS ACB). Document _MCP Cloning_ covers the requirements for a successful use of U-ADS ACB. The remaining requirements for a successful deployment are

* _MCP user account_: This account grants access to https://login.mcp.nasa.gov/.
* _MCP GitLab account_: This account grants access to https://gitlab.mcp.nasa.gov/.
* _MCP registration token for GitLab executors_: Section _GitLab_ of this README file explaines how to obtain the registration token for MCP GitLab.
* _Trigger token for [Unity-MCP-Clone](https://gitlab.mcp.nasa.gov/unity/unity-mcp-clone)_: This is the trigger token for https://gitlab.mcp.nasa.gov/unity/unity-mcp-clone git project, which can be accessed after logging into MCP GitLab.

### Deployment Steps

Follow these steps to deploy U-ADS ACB:
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

After entering the commnad _terraform apply_, first your are prompted to enter the gitlab runner registration token, then you are prompted to confirm the deployment by entring _yes_.

### Unity API Gateway Deployment and Stage

### What to Expect



For each entry in the list given in  _gl_executor_ids.tf_  file, the software
1. creates an EC2 instance
2. runs the file  *install_group_runner_x86_64_\<list entry\>.tftpl*  to prepare the EC2 instance environment:
   * downloads and installs gitlab runner binary
   * registers a gitlab executor
   * downloads and installs all needed tools and libraries needed for the executor to execute pipeline jobs assigned to it 

The registered executors will appear at the Unity group CI/CD.  To see a list of registered executors,
1. Log in to MCP GitLab
2. starting from top menu bar, go to
   * Main menu  >  Groups  >  Your groups  >  Unity
3. starting from left side-bar, go to
   * CI/CD  >  Runners

Each gitlab executor may have a set of one or more tags.  GitLab will assign a pipeline job with tags only to an executor with the same tags for execution.  Executor tags (if any) can be seen at the location mentioned above, where you can see a list of registered executors.

Currently the software, without any modification, will only register one gitlab shell executor with _unity_ and _shell_ tags.  However, the software is developed enough to register a docker executor as well by simplly adding _"docker"_ to the list in _gl_executor_ids.tf_ file.

A *.tftpl* filename, like the one mentioned above, is internally generated based on a templatized filename of the form

* install_group_runner_\<architecture\>_\<list entry\>.tftpl

The second parameter *\<list entry\>* was already discussed above.  The first parameter *\<architecture\>* is replaced with the selected architecture for the EC2 instance.  The architecture argument to the terraform command can be provided through *gl_runner_architecture* terraform variable, which has a default value of *"x86_64"*.

The only variable of this terraform script that does not have a default value is *gl_runner_registration_token*.  Therefore, an argument for *gl_runner_registration_token* must be entered at the terraform command line or when prompted.
