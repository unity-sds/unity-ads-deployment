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

This software encapsulates the deployment of the Unity Algorithm Development Services (U-ADS) infrastructure into an MCP AWS enclave. It consists of Terraform scripts for GitLab CI/CD service.

<!-- example links>
[Website](INSERT WEBSITE LINK HERE) | [Docs/Wiki](INSERT DOCS/WIKI SITE LINK HERE) | [Discussion Board](INSERT DISCUSSION BOARD LINK HERE) | [Issue Tracker](INSERT ISSUE TRACKER LINK HERE)
-->

## Features

Deploys Unity ADS services:

* GitLab CI/CD


## Gitlab CI/CD

This Terraform software deploys gitlab CI/CD service into MCP AWS, which is needed to execute a gitlab project CI/CD pipeline.  A gitlab system has two major components:

1. gitlab instance (not deployed by this software)
2. gitlab runners (deployed by this software)

### GitLab Instance

This software does not deploy any gitlab instance.  Unity project uses MCP (Mission Cloud Platform) GitLab provided by Goddard for its git repository management.  The MCP GitLab URL is https://gitlab.mcp.nasa.gov.  To request an MCP GitLab lisence, follow the instructions at
	https://caas.gsfc.nasa.gov/display/GSD1/Requesting+Access+to+GitLab+Ultimate
and choose “Project Owner” for the “Gitlab Role”.


### Gitlab runners

This terraform software deploys gitlab runners in MCP cloud environment and registers them at MCP GitLab.  It creates two types of dedicated AWS resources:

1. A security group for communication with EC2 instances (Security group name = GitLab Runner Security Group)
2. EC2 instances for gitlab runners (one instance per runner) (name = unity-ads-gl-runner-*)

Each runner has its own dedicated EC2 instance.


## A Brief Software Description

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

### Registration Token

Gitlab executor registration process requires a registration token.  This software defines the variable

* _gl_runner_registration_token_

for entering the current registration token.  To see the token at MCP GitLab
1. Log in to MCP GitLab
2. starting from top menu bar, go to
   * Main menu  >  Groups  >  Your groups  >  Unity
3. starting from left side-bar, go to
   * CI/CD  >  Runners
4. on the right side of the location above the area where registered executors are listed, go to
   * Register a group runner  >  Registration token
5. click on the eye icon to see the registration token

The registration token can be reset at this same location.
