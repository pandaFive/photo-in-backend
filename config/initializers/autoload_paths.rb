# Zeitwerk namespace mappings for non-standard directories
module Validators; end
module Policies; end
module Presenters; end
module Services; end
module Domain; end

Rails.autoloaders.main.push_dir(Rails.root.join("app/validators"), namespace: Validators)
Rails.autoloaders.main.push_dir(Rails.root.join("app/policies"), namespace: Policies)
Rails.autoloaders.main.push_dir(Rails.root.join("app/presenters"), namespace: Presenters)
Rails.autoloaders.main.push_dir(Rails.root.join("app/services"), namespace: Services)
Rails.autoloaders.main.push_dir(Rails.root.join("app/domain"), namespace: Domain)
