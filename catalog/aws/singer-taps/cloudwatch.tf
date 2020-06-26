locals {
  cloudwatch_query_text      = <<EOF
filter @message like /(Beginning|Completed) running/
| filter @message not like /running discovery/
| filter @message not like /\s--discover\s/
| parse @message "catalog/${var.taps[0].id}-*-catalog.json" as tablename
| parse @message " (* elapsed)" as elapsed
| fields @timestamp, @message
| sort tablename desc, @timestamp desc
EOF
  cloudwatch_errors_query    = <<EOF
filter @message like /level=CRITICAL/
| fields @timestamp, @message
| sort @timestamp desc
| limit 20
EOF
  cloudwatch_clean_log_query = <<EOF
filter @message not like /INFO\sUsed/
| filter @message not like /INFO\sMaking\sGET\srequest/
| filter @message not like /INFO\sMETRIC/
| fields @timestamp, @message
| sort @timestamp desc
EOF
  dashboard_markdown         = <<EOF
## Data Pipeline (${var.taps[0].id}-to-${local.target.id})

Additional Actions:

 - [View Running ECS Tasks](https://console.aws.amazon.com/ecs/home?region=${var.environment.aws_region}#/clusters/${module.ecs_cluster.ecs_cluster_name}/tasks)
 - [View ECS CloudWatch Logs](${module.ecs_tap_sync_task.ecs_logging_url})
 - [Open Step Function Console](${module.step_function.state_machine_url})

EOF
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.taps[0].id}-to-${local.target.id}-v${var.pipeline_version_number}-dashboard--${var.name_prefix}-Tap"
  dashboard_body = <<EOF
{
  "periodOverride": "auto",
  "widgets": [
    {
      "type": "text",
      "x": 0,
      "y": 0,
      "width": 10,
      "height": 4,
      "properties": {
        "markdown": "${
  replace(replace(replace(local.dashboard_markdown, "\\", "\\\\"), "\n", "\\n"), "\"", "\\\"")
  }"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 4,
      "width": 10,
      "height": 4,
      "properties": {
        "metrics": [
          [
            "ECS/ContainerInsights", "TaskCount",
            "ClusterName", "${module.ecs_cluster.ecs_cluster_name}"
          ]
        ],
        "period": 60,
        "stat": "Average",
        "region": "${var.environment.aws_region}",
        "title": "Running ECS Task",
        "yAxis": {
          "left": {
            "min": 0,
            "showUnits": false
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 8,
      "width": 10,
      "height": 4,
      "properties": {
        "metrics": [
          [ "ECS/ContainerInsights", "CpuReserved", "ClusterName", "${module.ecs_cluster.ecs_cluster_name}", { "id": "m1", "yAxis": "right", "visible": false  } ],
          [ ".", "CpuUtilized", ".", ".", { "id": "m2", "yAxis": "right" } ],
          [ ".", "MemoryReserved", ".", ".", { "id": "m3", "yAxis": "right", "visible": false  } ],
          [ ".", "MemoryUtilized", ".", ".", { "id": "m4", "yAxis": "right" } ],
          [ { "expression": "100*(m2/m1)", "label": "CpuUtilization", "id": "e1" } ],
          [ { "expression": "100*(m4/m3)", "label": "MemoryUtilization", "id": "e2" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${var.environment.aws_region}",
        "stat": "Average",
        "period": 300,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100,
            "label": "Percentage Usage"
          },
          "right": {
            "label": "Reserved | Utilized",
            "showUnits": false,
            "min": 0
          }
        },
        "legend": {
          "position": "bottom"
        }
      }
    },
    {
      "type": "log",
      "x": 10,
      "y": 0,
      "width": 14,
      "height": 12,
      "properties": {
        "query": "SOURCE '${module.ecs_tap_sync_task.cloudwatch_log_group_name}' | ${
  replace(replace(replace(local.cloudwatch_query_text, "\\", "\\\\"), "\n", "\\n"), "\"", "\\\"")
  }",
        "region": "${var.environment.aws_region}",
        "stacked": "false",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 10,
      "width": 24,
      "height": 3,
      "properties": {
        "query": "SOURCE '${module.ecs_tap_sync_task.cloudwatch_log_group_name}' | ${
  replace(replace(replace(local.cloudwatch_errors_query, "\\", "\\\\"), "\n", "\\n"), "\"", "\\\"")
  }",
        "region": "${var.environment.aws_region}",
        "stacked": "false",
        "view": "table"
      }
    },
    {
      "type": "log",
      "x": 0,
      "y": 13,
      "width": 24,
      "height": 12,
      "properties": {
        "query": "SOURCE '${module.ecs_tap_sync_task.cloudwatch_log_group_name}' | ${
  replace(replace(replace(local.cloudwatch_clean_log_query, "\\", "\\\\"), "\n", "\\n"), "\"", "\\\"")
}",
        "region": "${var.environment.aws_region}",
        "stacked": "false",
        "view": "table"
      }
    }
  ]
}
EOF
}
