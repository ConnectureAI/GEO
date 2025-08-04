
import { DataTypes, Model, Sequelize } from 'sequelize';

export class Competitor extends Model {
  public id!: string;
  public clinicId!: string;
  public name!: string;
  public domain!: string;
  public location!: object;
  public marketPosition!: number;
  public monitoringEnabled!: boolean;
  public metrics!: object;
  public discoveredAt!: Date;
  public lastAnalyzed!: Date;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

export const initCompetitorModel = (sequelize: Sequelize) => {
  Competitor.init(
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      clinicId: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
          model: 'clinics',
          key: 'id',
        },
      },
      name: {
        type: DataTypes.STRING,
        allowNull: false,
      },
      domain: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true,
      },
      location: {
        type: DataTypes.JSONB,
        allowNull: false,
      },
      marketPosition: {
        type: DataTypes.INTEGER,
        allowNull: true,
      },
      monitoringEnabled: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      metrics: {
        type: DataTypes.JSONB,
        allowNull: true,
      },
      discoveredAt: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
      },
      lastAnalyzed: {
        type: DataTypes.DATE,
        allowNull: true,
      },
    },
    {
      sequelize,
      tableName: 'competitors',
    }
  );
};
