# Copyright 2016 The OPA Authors.  All rights reserved.
# Use of this source code is governed by an Apache2
# license that can be found in the LICENSE file.

# The "package" provides namespaces the rules contained inside this
# definition. The package directive controls where the Virtual Documents
# defined by the rules are located under the Data API. In this case,
# the documents are available under /v1/data/opa/example/.
package opa.example

# The "import" directive declares a dependency on a document outside this
# package. The import directive is used to declare dependencies on both
# input documents AND documents stored in OPA (e.g., data.users below).
import request as req
import data.users

# allow_request defines a document that is the boolean value true if (and only if)
# all of the expressions in the body are true. If any of the expressions in the body
# are false, the document is undefined. Rego allows you to omit the "= true" portion
# for conciseness.
allow_request = true :-
    not invalid_network,
    not seccomp_unconfined,
    valid_user_role

invalid_network :-
    # These expressions assert that a container with a special label must be
    # connected to a specific network.
    labels["com.example/deployment"] = "prod",
    req.Path = "/v1.23/containers/create",
    req.Body.HostConfig.NetworkMode != "prod-network"

seccomp_unconfined :-
    # This expression asserts that the string on the right hand side exists
    # within the array SecurityOpt referenced on the left hand side.
    req.Path = "/v1.23/containers/create",
    req.Body.HostConfig.SecurityOpt[_] = "seccomp=unconfined"

# valid_user_role defines a document that is the boolean value true if this is
# a write request and the user is allowed to perform writes.
valid_user_role :-
    req.Headers["Authz-User"] = user_id,
    users[user_id] = user,
    req.Method != "GET",
    user.readOnly = false

# valid_user_role is defined again here to handle read requests. When a rule
# like this is defined multiple times, the rule definition must ensure that
# only one instance evaluates successfully in a given query. If multiple
# instances evaluated successfully, it indicates a conflict.
valid_user_role :-
    req.Headers["Authz-User"] = user_id,
    req.Method = "GET",
    users[user_id] = user

# labels defines an object document that simply contains the labels from the
# requested container.
labels[key] = value :- req.Body.Labels[key] = value
