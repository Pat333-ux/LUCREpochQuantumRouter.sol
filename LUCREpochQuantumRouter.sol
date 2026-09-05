// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LUCREpochQuantumRouter {
    address public governance;

    struct Target {
        address module;
        bool enabled;
    }

    mapping(bytes32 => Target) public targets;

    event TargetRegistered(bytes32 indexed key, address module, uint256 blockNum);
    event TargetUpdated(bytes32 indexed key, address oldModule, address newModule, uint256 blockNum);
    event TargetToggled(bytes32 indexed key, bool enabled, uint256 blockNum);
    event EpochQuantumBindingRouted(
        bytes32 indexed key,
        bytes32 epochQuantumBindingHash,
        uint256 blockNum
    );

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not governance");
        _;
    }

    constructor() {
        governance = msg.sender;
    }

    function registerTarget(bytes32 key, address module) external onlyGovernance {
        require(module != address(0), "Invalid module");
        require(targets[key].module == address(0), "Already registered");

        targets[key] = Target({module: module, enabled: true});
        emit TargetRegistered(key, module, block.number);
    }

    function updateTarget(bytes32 key, address newModule) external onlyGovernance {
        require(newModule != address(0), "Invalid module");
        require(targets[key].module != address(0), "Not registered");

        address old = targets[key].module;
        targets[key].module = newModule;

        emit TargetUpdated(key, old, newModule, block.number);
    }

    function toggleTarget(bytes32 key, bool enabled) external onlyGovernance {
        require(targets[key].module != address(0), "Not registered");
        targets[key].enabled = enabled;

        emit TargetToggled(key, enabled, block.number);
    }

    function routeEpochQuantumBinding(bytes32 key, bytes32 epochQuantumBindingHash)
        external
        onlyGovernance
    {
        Target memory t = targets[key];
        require(t.enabled, "Target disabled");
        require(t.module != address(0), "Invalid target");

        (bool ok, ) = t.module.call(
            abi.encodeWithSignature(
                "receiveEpochQuantumBinding(bytes32)",
                epochQuantumBindingHash
            )
        );
        require(ok, "Routing failed");

        emit EpochQuantumBindingRouted(
            key,
            epochQuantumBindingHash,
            block.number
        );
    }
}
