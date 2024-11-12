load("@ytt:struct", "struct")

def packages_with_configure_db(packages = []):
    result = []
    for package in packages:
        if hasattr(package, "configure_db"):
            if package.configure_db:
                if hasattr(package, "acceptance"):
                    if not package.acceptance:
                        result.append(package)
                    end
                else:
                    result.append(package)
                end
            end
        end
    end
    return result
end

def packages_without_configure_db(packages = []):
    result = []
    for package in packages:
        if not hasattr(package, "configure_db"):
            if hasattr(package, "acceptance"):
                if not package.acceptance:
                    result.append(package)
                end
            else:
                result.append(package)
            end
        elif not package.configure_db:
            if hasattr(package, "acceptance"):
                if not package.acceptance:
                    result.append(package)
                end
            else:
                result.append(package)
            end
        end
    end
    return result
end

def packages_with_a_git_repo(packages = []):
    result = []
    for package in packages:
        if hasattr(package, "same_repo"):
            if not package.same_repo:
                result.append(package)
            end
        else:
            result.append(package)
        end
    end
    return result
end

def on_windows(package):
    if hasattr(package, "on_windows"):
        if package.on_windows:
            return True
        end
    end
    return False
end

def privileged(package):
    if hasattr(package, "privileged"):
        if package.privileged:
            return True
        end
    end
    return False
end

def packages_names_array(packages = [], prefixes = []):
    result = []
    for package in packages:
        if hasattr(package, "name"):
            if package.name:
                if len(prefixes) == 0:
                    result.append(package.name)
                else:
                    for prefix in prefixes:
                        result.append(prefix + package.name)
                    end
                end
            end
        end
    end
    return result
end

def packages_names_array_without_acceptance(packages = [], prefixes = []):
    result = []
    for package in packages:
        if hasattr(package, "name"):
            if package.name:
                if len(prefixes) == 0:
                    result.append(package.name)
                else:
                    for prefix in prefixes:
                        result.append(prefix + package.name)
                    end
                end
            end
        end
    end
    return result
end

def on_branch(package):
    if hasattr(package, "on_branch"):
        if package.on_branch:
            return package.on_branch
        end
    end
    return "main"
end

helpers = struct.make(
    packages_with_configure_db=packages_with_configure_db,
    packages_without_configure_db=packages_without_configure_db,
    packages_with_a_git_repo=packages_with_a_git_repo,
    packages_names_array=packages_names_array,
    packages_names_array_without_acceptance=packages_names_array_without_acceptance,
    on_windows=on_windows,
    privileged=privileged,
    on_branch=on_branch,
)

