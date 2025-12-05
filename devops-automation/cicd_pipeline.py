#!/usr/bin/env python3
"""
CI/CD Pipeline Automation Tool
Automated deployment pipeline management for Jenkins, GitLab CI, and GitHub Actions
Built on 15+ years of DevOps experience achieving 80% automation of manual tasks
"""

import os
import sys
import json
import subprocess
import requests
from datetime import datetime
import yaml
import argparse

class CICDPipelineManager:
    def __init__(self, platform='jenkins', config_file='config.json'):
        self.platform = platform
        self.config = self.load_config(config_file)
        self.api_token = os.getenv(f'{platform.upper()}_API_TOKEN')
        self.base_url = self.config.get('base_url')
        
    def load_config(self, config_file):
        """Load configuration from JSON file"""
        try:
            with open(config_file, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"Warning: Config file {config_file} not found. Using defaults.")
            return {}
    
    def trigger_jenkins_build(self, job_name, parameters=None):
        """Trigger Jenkins job with optional parameters"""
        url = f"{self.base_url}/job/{job_name}/buildWithParameters"
        headers = {'Authorization': f'Bearer {self.api_token}'}
        
        try:
            response = requests.post(url, headers=headers, data=parameters)
            if response.status_code == 201:
                print(f"Successfully triggered Jenkins job: {job_name}")
                return response.headers.get('Location')
            else:
                print(f"Failed to trigger job. Status: {response.status_code}")
                return None
        except Exception as e:
            print(f"Error triggering Jenkins build: {str(e)}")
            return None
    
    def get_build_status(self, job_name, build_number):
        """Get Jenkins build status"""
        url = f"{self.base_url}/job/{job_name}/{build_number}/api/json"
        headers = {'Authorization': f'Bearer {self.api_token}'}
        
        try:
            response = requests.get(url, headers=headers)
            if response.status_code == 200:
                data = response.json()
                return {
                    'status': data.get('result', 'IN_PROGRESS'),
                    'duration': data.get('duration'),
                    'timestamp': data.get('timestamp'),
                    'url': data.get('url')
                }
        except Exception as e:
            print(f"Error fetching build status: {str(e)}")
            return None
    
    def generate_gitlab_ci(self, stages, jobs):
        """Generate GitLab CI/CD pipeline configuration"""
        pipeline = {
            'stages': stages,
            'variables': {
                'DOCKER_DRIVER': 'overlay2',
                'DOCKER_TLS_CERTDIR': '/certs'
            }
        }
        
        # Add jobs
        for job_name, job_config in jobs.items():
            pipeline[job_name] = {
                'stage': job_config.get('stage'),
                'script': job_config.get('script', []),
                'only': job_config.get('only', ['main']),
                'tags': job_config.get('tags', ['docker'])
            }
            
            # Add artifacts if specified
            if 'artifacts' in job_config:
                pipeline[job_name]['artifacts'] = job_config['artifacts']
        
        return yaml.dump(pipeline, default_flow_style=False)
    
    def generate_github_actions(self, workflow_name, triggers, jobs):
        """Generate GitHub Actions workflow"""
        workflow = {
            'name': workflow_name,
            'on': triggers,
            'jobs': {}
        }
        
        for job_name, job_config in jobs.items():
            workflow['jobs'][job_name] = {
                'runs-on': job_config.get('runs_on', 'ubuntu-latest'),
                'steps': job_config.get('steps', [])
            }
        
        return yaml.dump(workflow, default_flow_style=False)
    
    def deploy_to_kubernetes(self, namespace, deployment_file):
        """Deploy application to Kubernetes cluster"""
        try:
            cmd = f"kubectl apply -f {deployment_file} -n {namespace}"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"Successfully deployed to namespace: {namespace}")
                print(result.stdout)
                return True
            else:
                print(f"Deployment failed: {result.stderr}")
                return False
        except Exception as e:
            print(f"Error deploying to Kubernetes: {str(e)}")
            return False
    
    def run_terraform_apply(self, workspace, var_file=None):
        """Execute Terraform apply with workspace and variables"""
        try:
            # Select workspace
            subprocess.run(f"terraform workspace select {workspace}", shell=True)
            
            # Build apply command
            cmd = "terraform apply -auto-approve"
            if var_file:
                cmd += f" -var-file={var_file}"
            
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"Terraform apply successful for workspace: {workspace}")
                print(result.stdout)
                return True
            else:
                print(f"Terraform apply failed: {result.stderr}")
                return False
        except Exception as e:
            print(f"Error running Terraform: {str(e)}")
            return False
    
    def run_ansible_playbook(self, playbook, inventory, extra_vars=None):
        """Execute Ansible playbook"""
        try:
            cmd = f"ansible-playbook -i {inventory} {playbook}"
            if extra_vars:
                cmd += f" --extra-vars '{json.dumps(extra_vars)}'"
            
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"Ansible playbook executed successfully")
                print(result.stdout)
                return True
            else:
                print(f"Ansible playbook failed: {result.stderr}")
                return False
        except Exception as e:
            print(f"Error running Ansible: {str(e)}")
            return False
    
    def docker_build_and_push(self, image_name, tag, dockerfile_path, registry):
        """Build and push Docker image"""
        try:
            # Build image
            build_cmd = f"docker build -t {image_name}:{tag} -f {dockerfile_path} ."
            build_result = subprocess.run(build_cmd, shell=True, capture_output=True, text=True)
            
            if build_result.returncode != 0:
                print(f"Docker build failed: {build_result.stderr}")
                return False
            
            # Tag for registry
            full_image = f"{registry}/{image_name}:{tag}"
            tag_cmd = f"docker tag {image_name}:{tag} {full_image}"
            subprocess.run(tag_cmd, shell=True)
            
            # Push to registry
            push_cmd = f"docker push {full_image}"
            push_result = subprocess.run(push_cmd, shell=True, capture_output=True, text=True)
            
            if push_result.returncode == 0:
                print(f"Successfully pushed image: {full_image}")
                return True
            else:
                print(f"Docker push failed: {push_result.stderr}")
                return False
        except Exception as e:
            print(f"Error in Docker operations: {str(e)}")
            return False
    
    def send_slack_notification(self, webhook_url, message, status='info'):
        """Send Slack notification"""
        colors = {
            'success': '#36a64f',
            'failure': '#ff0000',
            'warning': '#ff9900',
            'info': '#439fe0'
        }
        
        payload = {
            'attachments': [{
                'color': colors.get(status, '#439fe0'),
                'text': message,
                'footer': 'CI/CD Pipeline',
                'ts': int(datetime.now().timestamp())
            }]
        }
        
        try:
            response = requests.post(webhook_url, json=payload)
            if response.status_code == 200:
                print("Slack notification sent successfully")
                return True
            else:
                print(f"Failed to send Slack notification: {response.status_code}")
                return False
        except Exception as e:
            print(f"Error sending Slack notification: {str(e)}")
            return False
    
    def generate_pipeline_report(self, builds):
        """Generate pipeline execution report"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'total_builds': len(builds),
            'successful': sum(1 for b in builds if b['status'] == 'SUCCESS'),
            'failed': sum(1 for b in builds if b['status'] == 'FAILURE'),
            'avg_duration': sum(b.get('duration', 0) for b in builds) / len(builds) if builds else 0,
            'builds': builds
        }
        
        # Save report
        report_file = f"pipeline_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"Pipeline report generated: {report_file}")
        return report


def main():
    parser = argparse.ArgumentParser(description='CI/CD Pipeline Automation Tool')
    parser.add_argument('--platform', choices=['jenkins', 'gitlab', 'github'], default='jenkins',
                        help='CI/CD platform')
    parser.add_argument('--action', required=True,
                        choices=['trigger', 'status', 'deploy', 'terraform', 'ansible', 'docker'],
                        help='Action to perform')
    parser.add_argument('--job-name', help='Job or pipeline name')
    parser.add_argument('--build-number', type=int, help='Build number')
    parser.add_argument('--namespace', help='Kubernetes namespace')
    parser.add_argument('--config', default='config.json', help='Configuration file')
    
    args = parser.parse_args()
    
    manager = CICDPipelineManager(platform=args.platform, config_file=args.config)
    
    if args.action == 'trigger' and args.job_name:
        manager.trigger_jenkins_build(args.job_name)
    elif args.action == 'status' and args.job_name and args.build_number:
        status = manager.get_build_status(args.job_name, args.build_number)
        print(json.dumps(status, indent=2))
    elif args.action == 'deploy' and args.namespace:
        manager.deploy_to_kubernetes(args.namespace, 'deployment.yaml')
    else:
        print("Invalid action or missing required parameters")
        parser.print_help()


if __name__ == '__main__':
    main()
