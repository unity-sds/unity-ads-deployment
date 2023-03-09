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

1. A security group for communication with EC2 instances:  Security group name = GitLab Runner Security Group
2. EC2 instances for gitlab runners (one instance per runner):  name = unity-ads-gl-runner-*

Each runner has its own dedicated EC2 instance.


# Software Description

For each entry in the list given in gl_executor_ids.tf file, the software
1. creates an EC2 instance
2. runs the file  install_group_runner_x86_64_<list entry>.tftpl  to prepare the EC2 instance environment:
   * downloads and installs gitlab runner binary
   * registers a gitlab executor
   * downloads and installs all needed tools and libraries needed for the executor to execute pipeline jobs

The registered executors will appear at the Unity group CI/CD.  To see a list of registered executors,
1. starting from top menu bar, go to
   * Main menu  >  Groups  >  Your groups  >  Unity
2. starting from left side-bar, go to
   * CI/CD  >  Runners
