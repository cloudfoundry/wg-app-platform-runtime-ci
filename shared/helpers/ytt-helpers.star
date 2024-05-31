load("@ytt:struct", "struct")

def packages_with_configure_db(packages = []):
    l = []
 for p in packages:
     if hasattr(p, "configure_db"):
         if p.configure_db:
     if hasattr(p, "acceptance"):
         if not p.acceptance:
             l.append(p)
     end
     else:
             l.append(p)
     end
     end
   end
 end
 return l
end

def packages_without_configure_db(packages = []):
    l = []
 for p in packages:
     if not hasattr(p, "configure_db"):
     if hasattr(p, "acceptance"):
         if not p.acceptance:
             l.append(p)
     end
     else:
             l.append(p)
     end
   elif not p.configure_db:
     if hasattr(p, "acceptance"):
         if not p.acceptance:
             l.append(p)
     end
     else:
             l.append(p)
     end
   end
 end
 return l
end

def packages_with_a_git_repo(packages = []):
    l = []
 for p in packages:
     if hasattr(p, "same_repo"):
         if not p.same_repo:
             l.append(p)
     end
     else:
         l.append(p)

   end
 end
 return l
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
    l = []
 for p in packages:
     if hasattr(p, "name"):
         if p.name:
            if len(prefixes) == 0:
                l.append(p.name)
            else:
                for prefix in prefixes:
                    l.append(prefix + p.name)
                end
            end
        end
    end
 end
 return l
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
    on_windows=on_windows,
    privileged=privileged,
    on_branch=on_branch,
)

