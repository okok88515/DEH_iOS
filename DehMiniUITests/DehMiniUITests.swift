//
//  DehMiniUITests.swift
//  DehMiniUITests
//
//  Created by 朱杏眉 on 2025/11/16.
//  Copyright © 2025 mmlab. All rights reserved.
//

import Testing
import XCTest
@testable import DEH_Mini_II

final class RegionViewTests: XCTestCase {

    func test_filterRegions_whenSearchTextEmpty_returnsAll() {
        // Arrange
        let regions = [
            Field(id: 1, name: "台北", info: ""),
            Field(id: 2, name: "台中", info: ""),
            Field(id: 3, name: "高雄", info: "")
        ]

        // Act
        let result = RegionView.filterRegions(regionList: regions, searchText: "")

        // Assert
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.map { $0.name }, ["台北", "台中", "高雄"])
    }

    func test_filterRegions_whenSearchTextIsPrefix_filtersByPrefix() {
        // Arrange
        let regions = [
            Field(id: 1, name: "台北", info: ""),
            Field(id: 2, name: "台中", info: ""),
            Field(id: 3, name: "高雄", info: ""),
            Field(id: 4, name: "台南", info: "")
        ]

        // Act
        let result = RegionView.filterRegions(regionList: regions, searchText: "台")

        // Assert
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.map { $0.name }, ["台北", "台中", "台南"])
    }

    func test_filterRegions_whenNoMatch_returnsEmpty() {
        // Arrange
        let regions = [
            Field(id: 1, name: "台北", info: ""),
            Field(id: 2, name: "台中", info: ""),
            Field(id: 3, name: "高雄", info: "")
        ]

        // Act
        let result = RegionView.filterRegions(regionList: regions, searchText: "花蓮")

        // Assert
        XCTAssertTrue(result.isEmpty)
    }
}

