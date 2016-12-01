Feature: Ript Setup

  @sudo @timeout-10
  Scenario: Partition chain is set up
    Given I have no iptables rules loaded
    When I run `ript rules diff examples/basic.rb`
    Then the output should match:
      """
      iptables --new-chain partition-a
      iptables --insert INPUT 1 --jump partition-a
      iptables --insert OUTPUT 1 --jump partition-a
      iptables --insert FORWARD 1 --jump partition-a
      iptables --table nat --new-chain partition-d
      iptables --table nat --insert PREROUTING 1 --jump partition-d
      iptables --table nat --new-chain partition-s
      iptables --table nat --insert POSTROUTING 1 --jump partition-s


      # basic-\w+
      iptables --table nat --new-chain basic-d\w+
      iptables --table nat --new-chain basic-s\w+
      iptables --new-chain basic-a\w+
      """
    Then the created chain name in all tables should match

  @sudo @timeout-10
  Scenario: Partition chain is only added once
    Given I have no iptables rules loaded
    When I run `ript rules apply examples/basic.rb`
    Then the output from "ript rules apply examples/basic.rb" should match:
      """
      iptables --new-chain partition-a
      iptables --insert INPUT 1 --jump partition-a
      iptables --insert OUTPUT 1 --jump partition-a
      iptables --insert FORWARD 1 --jump partition-a
      iptables --table nat --new-chain partition-d
      iptables --table nat --insert PREROUTING 1 --jump partition-d
      iptables --table nat --new-chain partition-s
      iptables --table nat --insert POSTROUTING 1 --jump partition-s


      # basic-\w+
      iptables --table nat --new-chain basic-d\w+
      iptables --table nat --new-chain basic-s\w+
      iptables --new-chain basic-a\w+
      """
    When I run `ript rules apply examples/partition-name-exactly-20-characters.rb`
    Then the output from "ript rules apply examples/partition-name-exactly-20-characters.rb" should contain exactly:
      """
      # name_exactly_20_char-dcddf5
      iptables --table nat --new-chain name_exactly_20_char-ddcddf5
      iptables --table nat --new-chain name_exactly_20_char-sdcddf5
      iptables --new-chain name_exactly_20_char-adcddf5



      """
    Then the created chain name in all tables should match
