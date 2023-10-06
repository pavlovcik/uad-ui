// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DiamondTestSetup.sol";

contract TestDiamond is DiamondTestSetup {
    function test_ShouldSupportInspectingFacetsAndFunctions() public {
        bool isSupported = IERC165(address(diamond)).supportsInterface(
            type(IDiamondLoupe).interfaceId
        );
        assertEq(isSupported, true);
    }

    function testHasMultipleFacets() public {
        assertEq(facetAddressList.length, 18);
    }

    function testFacetsHaveCorrectSelectors() public {
        for (uint256 i = 0; i < facetAddressList.length; i++) {
            bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(
                facetAddressList[i]
            );
            if (compareStrings(facetNames[i], "DiamondCutFacet")) {
                assertTrue(
                    sameMembers(fromLoupeFacet, selectorsOfDiamondCutFacet)
                );
            } else if (compareStrings(facetNames[i], "DiamondLoupeFacet")) {
                assertTrue(
                    sameMembers(fromLoupeFacet, selectorsOfDiamondLoupeFacet)
                );
            } else if (compareStrings(facetNames[i], "OwnershipFacet")) {
                assertTrue(
                    sameMembers(fromLoupeFacet, selectorsOfOwnershipFacet)
                );
            } else if (compareStrings(facetNames[i], "ManagerFacet")) {
                assertTrue(
                    sameMembers(fromLoupeFacet, selectorsOfManagerFacet)
                );
            }
        }
    }

    function testSelectors_ShouldBeAssociatedWithCorrectFacet() public {
        for (uint256 i; i < facetAddressList.length; i++) {
            if (compareStrings(facetNames[i], "DiamondCutFacet")) {
                for (uint256 j; j < selectorsOfDiamondCutFacet.length; j++) {
                    assertEq(
                        facetAddressList[i],
                        ILoupe.facetAddress(selectorsOfDiamondCutFacet[j])
                    );
                }
            } else if (compareStrings(facetNames[i], "DiamondLoupeFacet")) {
                for (uint256 j; j < selectorsOfDiamondLoupeFacet.length; j++) {
                    assertEq(
                        facetAddressList[i],
                        ILoupe.facetAddress(selectorsOfDiamondLoupeFacet[j])
                    );
                }
            } else if (compareStrings(facetNames[i], "OwnershipFacet")) {
                for (uint256 j; j < selectorsOfOwnershipFacet.length; j++) {
                    assertEq(
                        facetAddressList[i],
                        ILoupe.facetAddress(selectorsOfOwnershipFacet[j])
                    );
                }
            } else if (compareStrings(facetNames[i], "ManagerFacet")) {
                for (uint256 j; j < selectorsOfManagerFacet.length; j++) {
                    assertEq(
                        facetAddressList[i],
                        ILoupe.facetAddress(selectorsOfManagerFacet[j])
                    );
                }
            }
        }
    }
}
