#!/usr/bin/env cwl-runner
#
# annotate an existing submission with a string value
# (variations can be written to pass long or float values)
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python

inputs:
  - id: submissionId
    type: int
  - id: annotationName
    type: string
  - id: annotationValue
    type: string
  - id: private
    type: string?
  - id: synapseConfig
    type: File

arguments:
  - valueFrom: annotationSubmission.py
  - valueFrom: $(inputs.submissionId)
    prefix: -s
  - valueFrom: $(inputs.annotationName)
    prefix: -n
  - valueFrom: $(inputs.annotationValue)
    prefix: -v
  - valueFrom: $(inputs.private)
    prefix: -p
  - valueFrom: $(inputs.synapseConfig.path)
    prefix: -c

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: annotationSubmission.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import json
          if __name__ == '__main__':
            parser = argparse.ArgumentParser()
            parser.add_argument("-s", "--submissionId", required=True, help="Submission ID")
            parser.add_argument("-n", "--annotationName", required=True, help="Name of annotation to add")
            parser.add_argument("-v", "--annotationValue", required=True, help="Value of annotation")
            parser.add_argument("-p", "--private", required=False, help="Annotation is private to queue administrator(s)")
            parser.add_argument("-c", "--synapseConfig", required=True, help="credentials file")
            args = parser.parse_args()
            syn = synapseclient.Synapse(configPath=args.synapseConfig)
            syn.login()
            status = syn.getSubmissionStatus(args.submissionId)
            annot = {'isPrivate': args.private, 'key': args.annotationName, 'value': args.annotationValue}
            if not 'annotations' in status:
              status.annotations = {}
            if 'stringAnnos' not in status.annotations:
              status.annotations['stringAnnos']=[]
            stringAnnos=status.annotations['stringAnnos']
            foundIt=False
            for i in range(len(stringAnnos)):
              if stringAnnos[i]['key']==args.annotationName:
                foundIt=True
                stringAnnos[i]=annot
            if not foundIt:
              status.annotations['stringAnnos'].append(annot)
            status = syn.store(status)
     
outputs: []

