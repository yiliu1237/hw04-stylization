using UnityEditor;
using UnityEngine;
using System.Collections;

public class TerrainControlEditorWindow : EditorWindow
{
    private GameObject terrainPrefab;
    private int row = 10;
    private int col = 10;
    private ArrayList terrainList = new ArrayList();

    [MenuItem("Tools/Terrain Control")]
    public static void ShowWindow()
    {
        GetWindow<TerrainControlEditorWindow>("Terrain Control");
    }

    void OnGUI()
    {
        GUILayout.Label("Terrain Generation Settings", EditorStyles.boldLabel);

        // 选择地形预制体
        terrainPrefab = (GameObject)EditorGUILayout.ObjectField("Terrain Prefab", terrainPrefab, typeof(GameObject), false);

        // 行和列的滑块
        row = EditorGUILayout.IntSlider("Rows", row, 1, 50);
        col = EditorGUILayout.IntSlider("Columns", col, 1, 50);

        if (GUILayout.Button("Generate Terrain"))
        {
            GenerateTerrain();
        }

        if (GUILayout.Button("Clear Terrain"))
        {
            ClearTerrain();
        }
    }

    private void GenerateTerrain()
    {
        if (terrainPrefab == null)
        {
            Debug.LogWarning("Please assign a terrain prefab.");
            return;
        }

        // 查找或创建父对象Terrain
        GameObject parentObject = GameObject.Find("Terrain");
        if (parentObject == null)
        {
            parentObject = new GameObject("Terrain");
        }

        // 清除现有的地形
        ClearTerrain();

        Vector3 terrainSize = terrainPrefab.GetComponent<MeshFilter>().sharedMesh.bounds.size;
        // Get world size of terrain
        terrainSize = new Vector3(terrainSize.x * terrainPrefab.transform.localScale.x,
                                  terrainSize.y * terrainPrefab.transform.localScale.y,
                                  terrainSize.z * terrainPrefab.transform.localScale.z);

        // 创建新的地形块并设置父对象
        for (int i = 0; i < row; i++)
        {
            for (int j = 0; j < col; j++)
            {
                Vector3 position = new Vector3(i * terrainSize.x, 0, j * terrainSize.z);
                GameObject terrainBlock = (GameObject)PrefabUtility.InstantiatePrefab(terrainPrefab);
                terrainBlock.transform.position = position;
                terrainBlock.transform.parent = parentObject.transform; // 设置父对象
                terrainBlock.name = $"Terrain_{i}_{j}";
                terrainList.Add(terrainBlock);
            }
        }
    }

    private void ClearTerrain()
    {
        // 删除所有生成的地形
        foreach (GameObject terrain in terrainList)
        {
            if (terrain != null)
            {
                DestroyImmediate(terrain);
            }
        }
        terrainList.Clear();
    }
}
