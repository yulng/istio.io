#!/usr/bin/env bash
# shellcheck disable=SC2154

# Copyright 2023 Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GATEWAY_API="${GATEWAY_API:-false}"

# @setup profile=none

set -e
set -u
set -o pipefail

source "tests/util/samples.sh"

# install istio with ambient profile
snip_download_and_install_download_2
_wait_for_deployment istio-system istiod
_wait_for_daemonset istio-system ztunnel
_wait_for_daemonset istio-system istio-cni-node
_verify_like snip_download_and_install_download_4 "$snip_download_and_install_download_4_out"
_verify_like snip_download_and_install_download_5 "$snip_download_and_install_download_5_out"

# Kubernetes Gateway API CRDs are required by waypoint proxy.
snip_download_and_install_download_6

# deploy test application
startup_bookinfo_sample
snip_deploy_the_sample_application_bookinfo_2

if [ "$GATEWAY_API" == "true" ]; then
  snip_deploy_the_sample_application_bookinfo_5
  snip_deploy_the_sample_application_bookinfo_6
  snip_deploy_the_sample_application_bookinfo_7
else
  snip_deploy_the_sample_application_bookinfo_4
fi

_verify_contains snip_verify_traffic_sleep_to_ingress "$snip_verify_traffic_sleep_to_ingress_out"
_verify_contains snip_verify_traffic_sleep_to_productpage "$snip_verify_traffic_sleep_to_productpage_out"
_verify_contains snip_verify_traffic_notsleep_to_productpage "$snip_verify_traffic_notsleep_to_productpage_out"

snip_adding_your_application_to_ambient_addtoambient_1

# test traffic after ambient mode is enabled
_verify_contains snip_verify_traffic_sleep_to_ingress "$snip_verify_traffic_sleep_to_ingress_out"
_verify_contains snip_verify_traffic_sleep_to_productpage "$snip_verify_traffic_sleep_to_productpage_out"
_verify_contains snip_verify_traffic_notsleep_to_productpage "$snip_verify_traffic_notsleep_to_productpage_out"

snip_l4_authorization_policy_1
_verify_contains snip_verify_traffic_sleep_to_ingress "$snip_verify_traffic_sleep_to_ingress_out"
_verify_contains snip_verify_traffic_sleep_to_productpage "$snip_verify_traffic_sleep_to_productpage_out"
_verify_contains snip_verify_traffic_notsleep_to_productpage "command terminated with exit code 56"

_verify_contains snip_l7_authorization_policy_1 "$snip_l7_authorization_policy_1_out"
_verify_contains snip_l7_authorization_policy_2 "Resource programmed, assigned to service"

snip_l7_authorization_policy_3
_verify_contains snip_l7_authorization_policy_4 "$snip_l7_authorization_policy_4_out"
_verify_contains snip_l7_authorization_policy_5 "$snip_l7_authorization_policy_5_out"
_verify_contains snip_l7_authorization_policy_6 "$snip_l7_authorization_policy_6_out"

_verify_contains snip_control_traffic_control_1 "$snip_control_traffic_control_1_out"

if [ "$GATEWAY_API" == "true" ]; then
  snip_control_traffic_control_3
  snip_control_traffic_control_4
else
  snip_control_traffic_control_2
fi

_verify_lines snip_control_traffic_control_5 "
+ reviews-v1
+ reviews-v2
- reviews-v3
"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_uninstall_uninstall_1
    snip_uninstall_uninstall_2
    snip_uninstall_uninstall_3
    samples/bookinfo/platform/kube/cleanup.sh
    snip_uninstall_uninstall_4
fi
