#!/usr/bin/env bash
# network-helper.sh - Shared network helper for tfgrid-ai-stack on the VM

set -e

# Get network preference on the VM
# Priority:
#  1. /opt/tfgrid-ai-stack/.gitea_network_config (mycelium_network_preference)
#  2. DEPLOYMENT_NETWORK_PREFERENCE env var (if present)
#  3. Default: wireguard
get_network_preference_vm() {
    local network_preference="wireguard"

    if [ -f "/opt/tfgrid-ai-stack/.gitea_network_config" ]; then
        local net_pref_from_file
        net_pref_from_file=$(grep "^mycelium_network_preference:" /opt/tfgrid-ai-stack/.gitea_network_config 2>/dev/null | cut -d':' -f2 | tr -d ' ')
        if [ -n "$net_pref_from_file" ] && [ "$net_pref_from_file" != "unknown" ]; then
            network_preference="$net_pref_from_file"
        fi
    elif [ -n "${DEPLOYMENT_NETWORK_PREFERENCE:-}" ]; then
        network_preference="$DEPLOYMENT_NETWORK_PREFERENCE"
    fi

    echo "$network_preference"
}

# Locate the deployment state file on the VM
# Tries /tmp/app-deployment/state.yaml first, then parent
get_state_file_vm() {
    if [ -f "/tmp/app-deployment/state.yaml" ]; then
        echo "/tmp/app-deployment/state.yaml"
    elif [ -f "/tmp/app-deployment/../state.yaml" ]; then
        echo "/tmp/app-deployment/../state.yaml"
    else
        echo ""
    fi
}

# Get both VM and Mycelium IPs from state
# Output format: "ipv4_address|mycelium_address"
get_ips_vm() {
    local state_file
    state_file=$(get_state_file_vm)
    local ipv4_address="" mycelium_address=""

    if [ -n "$state_file" ]; then
        ipv4_address=$(grep "^ipv4_address:" "$state_file" 2>/dev/null | head -n1 | awk '{print $2}')
        mycelium_address=$(grep "^mycelium_address:" "$state_file" 2>/dev/null | head -n1 | awk '{print $2}')
    fi

    echo "$ipv4_address|$mycelium_address"
}

# Get the preferred deployment IP based on network preference
# Respects Mycelium preference but falls back to WireGuard if needed
get_deployment_ip_vm() {
    local pref
    pref=$(get_network_preference_vm)

    local ips ipv4_address myc_ip
    ips=$(get_ips_vm)
    ipv4_address=$(echo "$ips" | cut -d'|' -f1)
    myc_ip=$(echo "$ips" | cut -d'|' -f2)

    if [ "$pref" = "mycelium" ] && [ -n "$myc_ip" ]; then
        echo "$myc_ip"
    else
        echo "$ipv4_address"
    fi
}

# Convenience helper to return both IPs
get_both_ips_vm() {
    get_ips_vm
}

export -f get_network_preference_vm
export -f get_state_file_vm
export -f get_ips_vm
export -f get_deployment_ip_vm
export -f get_both_ips_vm
