variable "repository" {
  description = "A set of GitHub repository names."
  type        = set(string)
  nullable    = false

  validation {
    condition     = alltrue([for r in var.repository : can(regex("^[A-Za-z0-9_.-]+$", trimspace(r)))])
    error_message = "Repository names must match ^[A-Za-z0-9_.-]+$."
  }
}

variable "branch" {
  description = <<-EOF
    Pull request branch configuration:
      base: Target branch the pull request is merged into. Defaults to main
      compare: Source branch containing the changes. Defaults to feat/<random>
  EOF

  type = optional(object({
    base    = optional(string, "main")
    compare = optional(string)
  }), {})
  nullable = false

  validation {
    condition     = can(regex("^[A-Za-z0-9._/-]+$", var.branch.base)) && !can(regex("\\.\\.|//|^/|/$", var.branch.base))
    error_message = "branch.base must be a valid branch name."
  }

  validation {
    condition     = var.branch.compare == null || (can(regex("^[A-Za-z0-9._/-]+$", var.branch.compare)) && !can(regex("\\.\\.|//|^/|/$", var.branch.compare)))
    error_message = "branch.compare must be a valid branch name when set."
  }
}

variable "commit" {
  description = <<-EOF
    List of commits to include in pull request:
      message: Commit message.
      add_files: Set of file paths to add or update in the commit.
      remove_files: Set of file paths to delete in the commit.
  EOF

  type = optional(list(object({
    message      = optional(string)
    add_files    = optional(set(string), [])
    remove_files = optional(set(string), [])
  })), [])
  nullable = false

  validation {
    condition     = alltrue([for c in var.commit : c.message == null || can(regex("^.+$", trimspace(c.message)))])
    error_message = "commit.message must be non-empty when set."
  }

  validation {
    condition = alltrue([
      for c in var.commit :
      alltrue([for p in coalesce(c.add_files, []) : can(regex("^[^\\r\\n].*$", p)) && !can(regex("^/", p))]) &&
      alltrue([for p in coalesce(c.remove_files, []) : can(regex("^[^\\r\\n].*$", p)) && !can(regex("^/", p))])
    ])
    error_message = "File paths must be relative (no leading '/') and must not contain newlines."
  }

  validation {
    condition     = alltrue([for c in var.commit : length(setintersection(coalesce(c.add_files, []), coalesce(c.remove_files, []))) == 0])
    error_message = "A file path cannot be in both add_files and remove_files within the same commit."
  }
}

variable "author" {
  description = <<-EOF
    Commit author configuration:
      name: Author name used for commits.
      email: Author email used for commits.
  EOF

  type     = optional(object({
    name  = optional(string)
    email = optional(string)
  }), {})
  nullable = false

  validation {
    condition     = (var.author.name == null) == (var.author.email == null)
    error_message = "author.name and author.email must either both be set or both be null."
  }

  validation {
    condition     = var.author.email == null || can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", var.author.email))
    error_message = "author.email must look like a valid email address when set."
  }
}
