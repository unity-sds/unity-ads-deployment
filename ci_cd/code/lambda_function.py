import json
import os
import subprocess
import jwt

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


def get_end_user_info(event):
    cgroup = None
    cuser = None
    try:
        if (event['headers']) and (event['headers']['Authorization']) and (event['headers']['Authorization'] != None):
            cog_auth_token = event['headers']['Authorization'].split(' ')[1]
            jwt_dict = jwt.decode(cog_auth_token, options={"verify_signature": False})
            cgroup = jwt_dict['cognito:groups']
            cuser = jwt_dict['username']
    except KeyError:
        print('No cognito authorization token')
    return cuser, cgroup


def get_api_argument(event, my_key):
    # The following nested try/except statments enable several ways to
    # pass API arguments to Lambda function. They are:
    #
    #  - aws cli:
    #
    #      aws lambda invoke lambda-output --invocation-type RequestResponse \
    #        --function-name Unity-ADS--MCP-Clone --region us-west-2 \
    #        --payload '{"<key>" : "<value>"}'
    #
    #  - curl / query string parameter:
    #
    #      curl -X GET 'https://1gp9st60gd.execute-api.us-west-2.amazonaws.com/dev/ads/mcp-clone/?<key>=<value>'
    #
    #  - curl / header parameter:
    #
    #      curl -X GET https://1gp9st60gd.execute-api.us-west-2.amazonaws.com/dev/ads/mcp-clone \
    #        -H 'content-type: application/json' -H '<key>: <value>'
    #
    #  - curl / body:
    #
    #      curl -X GET https://1gp9st60gd.execute-api.us-west-2.amazonaws.com/dev/ads/mcp-clone \
    #        -H 'content-type: application/json' -d '{ "<key>": "<value>" }'
    #
    # Nested try/except does not work here.
    #
    ret_val = None
    try:
        if (event[my_key]) and (event[my_key] != None):
            ret_val = event[my_key]
            return ret_val
    except KeyError:
        ret_val = None
    try:
        if (event['queryStringParameters']) and (event['queryStringParameters'][my_key]) and (event['queryStringParameters'][my_key] != None):
            ret_val = event['queryStringParameters'][my_key]
            return ret_val
    except KeyError:
        ret_val = None
    try:
        if (event['multiValueHeaders']) and (event['multiValueHeaders'][my_key]) and (event['multiValueHeaders'][my_key] != None):
            ret_val = " and ".join(event['multiValueHeaders'][my_key])
            return ret_val
    except KeyError:
        ret_val = None
    try:
        if (event['headers']) and (event['headers'][my_key]) and (event['headers'][my_key] != None):
            ret_val = event['headers'][my_key]
            return ret_val
    except KeyError:
        ret_val = None 
    try:
        if (event['body']) and (event['body'] != None):
            body = json.loads(event['body'])
            if (body[my_key]) and (body[my_key] != None):
                ret_val = body[my_key]
                return ret_val
    except KeyError:
        ret_val = None

    return ret_val
    

def lambda_handler(event, context):
    # TODO implement
    id, token, ttoken = get_secret()

    apg_default_tag = '0.4.1'
    uag_default_tag = '0.3.0'

    apg_tag = get_api_argument(event, 'apg_tag') or apg_default_tag
    uag_tag = get_api_argument(event, 'uag_tag') or uag_default_tag
    clone_url = get_api_argument(event, 'clone_url')
    unity_venue = event['requestContext']['stage'].lower()

    cuser, cgroups = get_end_user_info(event)
    no_subgroup = True 
    if (cuser == None) or no_subgroup:
        curl_cmd_p = 'curl -X POST --fail ' \
            '-F token={0} ' \
            '-F "ref=main" ' \
            '-F "variables[MCP_GLU_ID_ES]={1}" ' \
            '-F "variables[MCP_ACCESS_TOKEN_ES]={2}" ' \
            '-F "variables[PROJ_TO_CLONE]={3}" ' \
            '-F "variables[APG_TAG]={4}" ' \
            '-F "variables[UAG_TAG]={5}" ' \
            '-F "variables[UNITY_VENUE]={6}" ' \
            'https://gitlab.mcp.nasa.gov/api/v4/projects/341/trigger/pipeline'
        curl_cmd = curl_cmd_p.format(ttoken, id, token, clone_url, apg_tag, uag_tag, unity_venue)
    else:
        curl_cmd_p = 'curl -X POST --fail ' \
            '-F token={0} ' \
            '-F "ref=main" ' \
            '-F "variables[MCP_GLU_ID_ES]={1}" ' \
            '-F "variables[MCP_ACCESS_TOKEN_ES]={2}" ' \
            '-F "variables[PROJ_TO_CLONE]={3}" ' \
            '-F "variables[SGROUP]={4}" ' \
            '-F "variables[APG_TAG]={5}" ' \
            '-F "variables[UAG_TAG]={6}" ' \
            '-F "variables[UNITY_VENUE]={7}" ' \
            'https://gitlab.mcp.nasa.gov/api/v4/projects/341/trigger/pipeline'
        curl_cmd = curl_cmd_p.format(ttoken, id, token, clone_url, cuser, apg_tag, uag_tag, unity_venue)

    print('========v unity-mcp-clone trigger command')
    print(curl_cmd)
    #
    cprocess = subprocess.run(curl_cmd, shell=True, capture_output=True, text=True)
    #
    print('========v unity-mcp-clone trigger stdout')
    print(cprocess.stdout)
    print('========v unity-mcp-clone trigger stderr')
    print(cprocess.stderr)
    print('========')

    response_body = {}
    response_body['clone_url'] = clone_url
    response_body['log_group_name'] = context.log_group_name
    response_body['apg_tag'] = apg_tag
    response_body['uag_tag'] = uag_tag
    
    response_http = {}
    response_http['statusCode'] = 200
    response_http['headers'] = {}
    response_http['headers']['Content-Type'] = 'application/json'
    response_http['body'] = json.dumps(response_body)

    return response_http
