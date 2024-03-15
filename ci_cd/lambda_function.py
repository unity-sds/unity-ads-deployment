import json
import os
import subprocess

import boto3
from botocore.exceptions import ClientError


def get_secret():

    secret_name = "MCP-GLU-Clone"
    region_name = "us-west-2"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e
    
    mcp_glu_id = (json.loads(get_secret_value_response['SecretString']))['MCP_GLU_ID_ES']
    mcp_glu_access_token = (json.loads(get_secret_value_response['SecretString']))['MCP_ACCESS_TOKEN_ES']
    mcp_glu_trigger_token = (json.loads(get_secret_value_response['SecretString']))['MCP_GLU_CLONE_PIPELINE_TT']
    return mcp_glu_id, mcp_glu_access_token, mcp_glu_trigger_token


def lambda_handler(event, context):
    # TODO implement
    id, token, ttoken = get_secret()
    
    # The following try/except statments enable several ways to remotely
    # call this Lambda function. They are:
    #
    #  - aws cli:
    #
    #      aws lambda invoke lambda-output --invocation-type RequestResponse \
    #        --function-name Unity-ADS--MCP-Clone --region us-west-2 \
    #        --payload '{"clone_url" : "<repo url to clone>"}'
    #
    #  - curl / query string parameter:
    #
    #      curl -X GET 'https://1gp9st60gd.execute-api.us-west-2.amazonaws.com/dev/ads/mcp-clone/?clone_url=<repo url to clone>'
    #
    #  - curl / header parameter:
    #
    #      curl -X GET https://1gp9st60gd.execute-api.us-west-2.amazonaws.com/dev/ads/mcp-clone \
    #        -H 'content-type: application/json' -H 'clone_url: <repo url to clone>'
    #
    #  - curl / body:
    #
    #      curl -X GET https://1gp9st60gd.execute-api.us-west-2.amazonaws.com/dev/ads/mcp-clone \
    #        -H 'content-type: application/json' -d '{ "clone_url": "<repo url to clone>" }'

    my_key = 'clone_url'
    clone_url = 'bad-url'
    try:
        if (event[my_key]) and (event[my_key] != None):
            clone_url = event[my_key]
    except KeyError:
        print('No clone_url')
    try:
        if (event['queryStringParameters']) and (event['queryStringParameters'][my_key]) and (event['queryStringParameters'][my_key] != None):
            clone_url = event['queryStringParameters'][my_key]
    except KeyError:
        print('No clone_url')
    try:
        if (event['multiValueHeaders']) and (event['multiValueHeaders'][my_key]) and (event['multiValueHeaders'][my_key] != None):
            clone_url = " and ".join(event['multiValueHeaders'][my_key])
    except KeyError:
        print('No clone_url')  
    try:
        if (event['headers']) and (event['headers'][my_key]) and (event['headers'][my_key] != None):
            clone_url = event['headers'][my_key]
    except KeyError:
        print('No clone_url')   
    try:
        if (event['body']) and (event['body'] != None):
            body = json.loads(event['body'])
            if (body[my_key]) and (body[my_key] != None):
                clone_url = body[my_key]
    except KeyError:
        print('No clone_url')
    
    curl_cmd_p = 'curl -X POST --fail ' \
       '-F token={0} ' \
       '-F "ref=main" ' \
       '-F "variables[MCP_GLU_ID_ES]={1}" ' \
       '-F "variables[MCP_ACCESS_TOKEN_ES]={2}" ' \
       '-F "variables[PROJ_TO_CLONE]={3}" ' \
       'https://gitlab.mcp.nasa.gov/api/v4/projects/341/trigger/pipeline'
    curl_cmd = curl_cmd_p.format(ttoken, id, token, clone_url)
    cprocess = subprocess.run(curl_cmd, shell=True, capture_output=True, text=True)

    response_body = {}
    response_body['clone_url'] = clone_url
    response_body['log_group_name'] = context.log_group_name
    
    response_http = {}
    response_http['statusCode'] = 200
    response_http['headers'] = {}
    response_http['headers']['Content-Type'] = 'application/json'
    response_http['body'] = json.dumps(response_body)

    return response_http
