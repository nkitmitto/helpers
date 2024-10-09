import json
import boto3
import pprint
import collections

iam = boto3.client('iam', region_name='us-east-1')
sts = boto3.client('sts', region_name='us-east-1')

class color:
   PURPLE = '\033[95m'
   CYAN = '\033[96m'
   DARKCYAN = '\033[36m'
   BLUE = '\033[94m'
   GREEN = '\033[92m'
   YELLOW = '\033[93m'
   RED = '\033[91m'
   BOLD = '\033[1m'
   UNDERLINE = '\033[4m'
   END = '\033[0m'

allRoles = []
rolesAndPolicies = collections.defaultdict(dict)
permissionsToScanFor = ['iam:Create*', 'iam:Attach*', 'secretsmanager:GetSecretValue', 'dynamodb:GetItem', 'sts:AssumeRole', 'cloudtrail:Stoplogging']

def getAllRoles():
    roles = iam.list_roles()
    while roles['IsTruncated']:
        marker = roles['Marker']
        roles = iam.list_roles(Marker=marker)
        for role in roles['Roles']:
            allRoles.append({'path': role['Path'], 'AssumeRolePolicyDocument': role['AssumeRolePolicyDocument'], 'RoleName': role['RoleName']})

    for role in roles['Roles']:
        allRoles.append({'path': role['Path'], 'AssumeRolePolicyDocument': role['AssumeRolePolicyDocument'], 'RoleName': role['RoleName']})

def getInlinePolicies(inlinePolicies, roleName):
    print(f"{color.BOLD}{color.GREEN}Welcome to Inline Policy Evaluation for {roleName}. {color.END}")
    for policy in inlinePolicies:
        iam.get_role_policy(
            RoleName=roleName,
            PolicyName=policy
        )

# Get the policy permissions and resources
def getPolicyDocument(policyName, policyArn, defaultVersionId, roleName):
    policyDocument = iam.get_policy_version(
        PolicyArn=policyArn,
        VersionId=defaultVersionId
    )
    # pprint.pp(policyDocument)
    pDoc = policyDocument['PolicyVersion']['Document']['Statement']
    for statement in pDoc:
        if "Action" in statement:
            for perm in permissionsToScanFor:
                if perm in statement['Action'] and statement['Effect'] != 'Deny':
                    print("Found protective permission:")
                    rolesAndPolicies[roleName].update({policyName: policyDocument['PolicyVersion']['Document']['Statement']})

# Get the list of policies and send each one through the getPolicyDocument function
def getAttachedPolicies(attachedPolicies, roleName):
    print(f"{color.BOLD}{color.GREEN}Welcome to Attached Policy Evaluation for {roleName}. {color.END}")
    for attachedPolicy in attachedPolicies:
        getPolicy = iam.get_policy(
            PolicyArn=f"{attachedPolicy['PolicyArn']}"
        )
        getPolicyDocument(getPolicy['Policy']['PolicyName'], getPolicy['Policy']['Arn'], getPolicy['Policy']['DefaultVersionId'], roleName)
    return

getAllRoles()

for role in allRoles:
    # for role in allRoles:
    if 'AssumeRolePolicyDocument' in role:
        policyDocument = role['AssumeRolePolicyDocument']
    roleName = role['RoleName']

    inlinePolicies = iam.list_role_policies(
        RoleName = roleName
    )

    attachedPolicies = iam.list_attached_role_policies(
        RoleName=roleName
    )

    # If inline policies exist, scan 'em
    if len(inlinePolicies['PolicyNames']) > 0:
        getInlinePolicies(inlinePolicies['PolicyNames'], roleName)
    else:
        print(f"{color.CYAN}{roleName} does not have any inline policies{color.END}")

    # If attached policies exist, scan 'em
    if len(attachedPolicies['AttachedPolicies']) > 0:
        getAttachedPolicies(attachedPolicies['AttachedPolicies'], roleName)
    else:
        print(f"{color.CYAN}{roleName} does not have any attached policies{color.END}")

pprint.pp(rolesAndPolicies)