function configure_cpu_entitlement_plugin() {
    cf uninstall-plugin CPUEntitlementPlugin || true
    cf install-plugin $CPU_ENTITLEMENT_PLUGIN_BINARY -f
}
export -f configure_cpu_entitlement_plugin

function configure_cpu_overentitlement_instances_plugin() {
    cf uninstall-plugin CPUEntitlementAdminPlugin || true
    cf install-plugin $CPU_OVERENTITLEMENT_INSTANCES_PLUGIN_BINARY -f
}
export -f configure_cpu_overentitlement_instances_plugin
