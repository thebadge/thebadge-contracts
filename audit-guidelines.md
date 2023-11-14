# Solidity Audit Scope for TheBadge

## Introduction
TheBadge is a novel decentralized platform that leverages the ERC1155 token standard to represent unique badges. These badges are issued as SBT NFTS (Soul-bonded tokens) and hold distinct on-chain information for each user. Unlike traditional tokens, SBTs cannot be transferred or traded, as they embody exclusive user-specific data.

TheBadge's architecture is divided into two key components: "Badge Models" and "Badges." Badge Models are defined by badge creators and serve as templates for generating actual badges that end-users will possess. A Badge Model specifies not only the visual design of the badge but also governs how the information within it should be displayed and validated.

## Objectives
The objectives of the audit are as follows:

1. Ensure that there are no significant issues within the smart contracts.
2. Identify and report possible security risks, entry points, or potential vulnerabilities.
3. Ensure that the code is clear, follows good development practices, and is understandable.

## In-Scope Items
The following smart contract files are within the audit scope:

```
- TheBadge.sol
- TheBadgeModels.sol
- TheBadgeStore.sol
- TheBadgeUsers.sol
- KlerosBadgeModelController.sol
- KlerosBadgeModelControllerStore.sol
- TpBadgeModelController.sol
- TpBadgeModelControllerStore.sol
```

Test folders related to these smart contracts are also included:

```
- BadgeModelControllers
- TheBadgeModels
- TheBadgeStore
- TheBadgeUsers
```

Note: the branch that should be considered for the audit is the ***v2-audit***

## Out-of-Scope Items
The following items are **NOT** within the audit scope:

- Library files
- Interface files
- Utility (Utils) files
- Initialization, upgrade, and deployment scripts
- Test files not specified in the "In-Scope Items" section
- Tests for TheBadge.sol (as these are a work in progress)

## Audit Approach
The audit will be conducted using a combination of manual code review, automated analysis tools, and testing. The primary focus will be on identifying security vulnerabilities, assessing code quality, and ensuring adherence to best development practices and industry standards.

## Testing Scenarios
The audit will consider various testing scenarios, including but not limited to:

1. Security vulnerabilities (e.g., reentrancy, overflow, underflow).
2. Functionality and business logic validation.
3. Gas efficiency and optimization.
4. Compliance with coding standards (e.g., ERC standards).

## Deliverables
The audit will produce the following deliverables:

- An initial draft report outlining encountered issues, vulnerabilities, and recommendations.
- A final audit report after the identified bugs and issues have been addressed.

## Timelines
The expected timeline for the audit will be communicated separately, with deadlines for various audit stages.

## Dependencies
The audit team may require access to the project team for clarifications or additional information during the audit process.

## Communication and Reporting
Communication between the audit team and the project team will be conducted according to the agreed-upon communication plan. Regular updates and progress reports will be provided, and issues will be documented in the audit report.

## Conclusion
We encourage open-source contributors to check out and collaborate on our project during this critical phase. Your contributions will be highly valued. We are offering bounties ranging from 100 up to 500 USD, depending on the quality of the audit report. Applications with examples or previous experiences will be considered when determining the bounty amount. Furthermore, all initial open-source contributors will receive extra points and future rewards as part of our open-source grant program.
