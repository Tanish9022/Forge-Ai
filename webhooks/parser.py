from typing import Any, Dict

def parse_issue_event(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Parses a GitLab issue event."""
    return {
        "event_type": "issue",
        "action": payload.get("object_attributes", {}).get("action"),
        "project_id": payload.get("project", {}).get("id"),
        "issue_iid": payload.get("object_attributes", {}).get("iid"),
        "title": payload.get("object_attributes", {}).get("title"),
        "description": payload.get("object_attributes", {}).get("description")
    }

def parse_push_event(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Parses a GitLab push event."""
    return {
        "event_type": "push",
        "project_id": payload.get("project", {}).get("id") or payload.get("project_id"),
        "ref": payload.get("ref"),
        "branch": payload.get("ref", "").split("/")[-1] if payload.get("ref") else None,
        "commits": payload.get("commits", []),
        "added_files": [f for commit in payload.get("commits", []) for f in commit.get("added", [])],
        "modified_files": [f for commit in payload.get("commits", []) for f in commit.get("modified", [])]
    }

def parse_mr_event(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Parses a GitLab merge request event."""
    return {
        "event_type": "merge_request",
        "action": payload.get("object_attributes", {}).get("action"),
        "project_id": payload.get("project", {}).get("id"),
        "mr_iid": payload.get("object_attributes", {}).get("iid"),
        "source_branch": payload.get("object_attributes", {}).get("source_branch"),
        "target_branch": payload.get("object_attributes", {}).get("target_branch"),
        "user_username": payload.get("user", {}).get("username")
    }

def parse_note_event(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Parses a GitLab note (comment) event."""
    # Could be on an issue or an MR
    object_attributes = payload.get("object_attributes", {})
    noteable_type = object_attributes.get("noteable_type")
    
    data = {
        "event_type": "note",
        "project_id": payload.get("project", {}).get("id"),
        "note": object_attributes.get("note"),
        "noteable_type": noteable_type
    }
    
    if noteable_type == "Issue":
        data["issue_iid"] = payload.get("issue", {}).get("iid")
    elif noteable_type == "MergeRequest":
        data["mr_iid"] = payload.get("merge_request", {}).get("iid")
        
    return data
