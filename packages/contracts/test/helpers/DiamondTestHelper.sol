// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../../src/diamond/interfaces/IDiamondCut.sol";
import "../../src/diamond/interfaces/IDiamondLoupe.sol";

contract DiamondTestHelper is IDiamondCut, IDiamondLoupe, Test {
    uint256 private seed;

    modifier prankAs(address caller) {
        vm.startPrank(caller);
        _;
        vm.stopPrank();
    }

    function generateAddress(
        string memory _name,
        bool _isContract
    ) internal returns (address) {
        return generateAddress(_name, _isContract, 0);
    }

    function generateAddress(
        string memory _name,
        bool _isContract,
        uint256 _eth
    ) internal returns (address newAddress_) {
        seed++;
        newAddress_ = vm.addr(seed);

        vm.label(newAddress_, _name);

        if (_isContract) {
            vm.etch(newAddress_, "Generated Contract Address");
        }

        vm.deal(newAddress_, _eth);

        return newAddress_;
    }

    // remove index from bytes4[] array
    function removeElement(
        uint256 index,
        bytes4[] memory array
    ) public pure returns (bytes4[] memory) {
        bytes4[] memory newarray = new bytes4[](array.length - 1);
        uint256 j = 0;
        for (uint256 i = 0; i < array.length; i++) {
            if (i != index) {
                newarray[j] = array[i];
                j += 1;
            }
        }
        return newarray;
    }

    // remove value from bytes4[] array
    function removeElement(
        bytes4 el,
        bytes4[] memory array
    ) public pure returns (bytes4[] memory) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return removeElement(i, array);
            }
        }
        return array;
    }

    function containsElement(
        bytes4[] memory array,
        bytes4 el
    ) public pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return true;
            }
        }
        return false;
    }

    function containsElement(
        address[] memory array,
        address el
    ) public pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return true;
            }
        }
        return false;
    }

    function sameMembers(
        bytes4[] memory array1,
        bytes4[] memory array2
    ) public pure returns (bool) {
        if (array1.length != array2.length) {
            return false;
        }
        for (uint256 i = 0; i < array1.length; i++) {
            if (containsElement(array1, array2[i])) {
                return true;
            }
        }
        return false;
    }

    function getAllSelectors(
        address diamondAddress
    ) public view returns (bytes4[] memory) {
        Facet[] memory facetList = IDiamondLoupe(diamondAddress).facets();

        uint256 len = 0;
        for (uint256 i = 0; i < facetList.length; i++) {
            len += facetList[i].functionSelectors.length;
        }

        uint256 pos = 0;
        bytes4[] memory selectors = new bytes4[](len);
        for (uint256 i = 0; i < facetList.length; i++) {
            for (
                uint256 j = 0;
                j < facetList[i].functionSelectors.length;
                j++
            ) {
                selectors[pos] = facetList[i].functionSelectors[j];
                pos += 1;
            }
        }
        return selectors;
    }

    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // implement dummy override functions
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external {}

    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_) {}

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_)
    {}

    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_) {}

    function facets() external view returns (Facet[] memory facets_) {}
}
