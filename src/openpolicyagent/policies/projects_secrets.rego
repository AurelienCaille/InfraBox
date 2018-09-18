package infrabox

import input as api

import data.infrabox.collaborators.collaborators
import data.infrabox.projects.projects
import data.infrabox.roles

projects_secrets_administrator([user, project]){
    collaborators[i].project_id = project
    collaborators[i].user_id = user
    roles[collaborators[i].role] >= 2
}

# Allow GET access to /api/v1/projects/<project_id>/secrets for project administrators
allow {
    api.method = "GET"
    api.path = ["api", "v1", "projects", project_id, "secrets"]
    api.token.type = "user"
    projects_secrets_administrator([api.token.user.id, project_id])
}

# Allow POST access to /api/v1/projects/<project_id>/secrets for project administrators
allow {
    api.method = "POST"
    api.path = ["api", "v1", "projects", project_id, "secrets"]
    api.token.type = "user"
    projects_secrets_administrator([api.token.user.id, project_id])
}

# Allow DELETE access to /api/v1/projects/<project_id>/secrets/<secret_id> for project administrators
allow {
    api.method = "DELETE"
    api.path = ["api", "v1", "projects", project_id, "secrets", secret_id]
    api.token.type = "user"
    projects_secrets_administrator([api.token.user.id, project_id])
}