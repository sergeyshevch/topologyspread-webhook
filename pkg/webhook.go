/*
Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package pkg

import (
	"context"
	"fmt"
	"net/http"
	"strconv"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/util/json"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

// +kubebuilder:webhook:path=/mutate,admissionReviewVersions=v1,sideEffects=None,mutating=true,failurePolicy=fail,groups="",resources=pods,verbs=create;update,versions=v1,name=topologyspread-mutation.sergeyshevch.github.io

var preferredMaxSkewAnnotation = "preferred-max-skew.sergeyshevch.github.com"

type TopologySpreadMutator struct {
	Client                  client.Client
	PreferredMaxSkewDefault int
	decoder                 *admission.Decoder
}

func (a *TopologySpreadMutator) InjectDecoder(d *admission.Decoder) error {
	a.decoder = d
	return nil
}

func (a *TopologySpreadMutator) Handle(ctx context.Context, req admission.Request) admission.Response {
	pod := &corev1.Pod{}
	err := a.decoder.Decode(req, pod)
	if err != nil {
		return admission.Errored(http.StatusBadRequest, err)
	}

	preferredMaxSkew := int32(a.PreferredMaxSkewDefault)

	if value, ok := pod.Annotations[preferredMaxSkewAnnotation]; ok {
		intValue, err := strconv.ParseInt(value, 10, 32)
		if err != nil {
			return admission.Denied(fmt.Sprintf("%s annotation values cannot be parsed to int", preferredMaxSkewAnnotation))
		}

		preferredMaxSkew = int32(intValue)
	}

	// mutate the fields in pod
	if pod.Spec.Affinity == nil || pod.Spec.Affinity.PodAntiAffinity == nil {
		return admission.Allowed("Resource has no podAntiAffinity. No mutation required")
	}

	constraints := []corev1.TopologySpreadConstraint{}

	for _, requiredConstraint := range pod.Spec.Affinity.PodAntiAffinity.RequiredDuringSchedulingIgnoredDuringExecution {
		constraints = append(constraints, corev1.TopologySpreadConstraint{
			MaxSkew:           1,
			TopologyKey:       requiredConstraint.TopologyKey,
			WhenUnsatisfiable: corev1.DoNotSchedule,
			LabelSelector:     requiredConstraint.LabelSelector,
		})
	}

	for _, preferredConstraint := range pod.Spec.Affinity.PodAntiAffinity.PreferredDuringSchedulingIgnoredDuringExecution {
		constraints = append(constraints, corev1.TopologySpreadConstraint{
			MaxSkew:           preferredMaxSkew,
			TopologyKey:       preferredConstraint.PodAffinityTerm.TopologyKey,
			WhenUnsatisfiable: corev1.DoNotSchedule,
			LabelSelector:     preferredConstraint.PodAffinityTerm.LabelSelector,
		})
	}

	pod.Spec.TopologySpreadConstraints = append(pod.Spec.TopologySpreadConstraints, constraints...)
	pod.Spec.Affinity.PodAntiAffinity = nil

	marshaledPod, err := json.Marshal(pod)
	if err != nil {
		return admission.Errored(http.StatusInternalServerError, err)
	}
	return admission.PatchResponseFromRaw(req.Object.Raw, marshaledPod)
}
